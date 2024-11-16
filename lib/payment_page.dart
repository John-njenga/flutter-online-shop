import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ticket_id.dart'; // Import your TicketIDPage here

class PaymentPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;

  PaymentPage({required this.cartItems, required this.totalAmount});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User? user;
  String userName = '';
  String userPhone = '';
  String deliveryAddress = '';
  bool canPayLater = false;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user!.uid).get();
      setState(() {
        userName = userDoc['name'] ?? '';
        userPhone = userDoc['phone'] ?? '';
      });
      _checkUserOrders();
    }
  }

  Future<void> _checkUserOrders() async {
    if (user != null) {
      QuerySnapshot ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: user!.uid)
          .get();

      setState(() {
        canPayLater = ordersSnapshot.docs.length > 3;
      });
    }
  }

  void _payNow() {
    if (deliveryAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a delivery address before proceeding.')),
      );
    } else {
      _showMpesaDialog();
    }
  }

  void _showMpesaDialog() {
    TextEditingController phoneController = TextEditingController();
    phoneController.text = userPhone;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("M-Pesa Payment", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Total Amount: Ksh ${widget.totalAmount}", style: TextStyle(fontSize: 16)),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: "Enter Phone Number"),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Pay Now", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _initiateMpesaPayment(phoneController.text, widget.totalAmount);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _initiateMpesaPayment(String phoneNumber, double amount) async {
    final url = 'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest';
    final consumerKey = 'YZ7ZZCuopMdH6jT9xseeFSjHNN53wuWk2CJZ11PFCpt7s4EN';  // Replace with your Consumer Key
    final consumerSecret = '5xS4SgKaGVdE9HF8hbwxnyjKPDBZXdxY9XUR5tEgWJA391wLlNbOsBNEShdFYpwL';  // Replace with your Consumer Secret

    try {
      String accessToken = await _getMpesaAccessToken(consumerKey, consumerSecret);

      Map<String, String> headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      String shortCode = "174379"; // Your short code
      String passkey = "bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919"; // Your passkey
      String timestamp = _getTimestamp();
      String password = base64Encode(utf8.encode(shortCode + passkey + timestamp));

      Map<String, dynamic> body = {
        "BusinessShortCode": shortCode,
        "Password": password,
        "Timestamp": timestamp,
        "TransactionType": "CustomerPayBillOnline",
        "Amount": amount.toInt(),
        "PartyA": phoneNumber,
        "PartyB": shortCode,
        "PhoneNumber": phoneNumber,
        "CallBackURL": "https://mydomain.com/path", // Change to your callback URL
        "AccountReference": "CakesByDarq",
        "TransactionDesc": "Payment for order",
      };

      final response = await http.post(Uri.parse(url), headers: headers, body: json.encode(body));

      if (response.statusCode == 200) {
        String transactionReference = json.decode(response.body)['CheckoutRequestID'];
        await _storeTransactionInFirestore(
          transactionReference,
          'successful',
          userName,
          widget.cartItems,
          amount, // Pass amount here
        );


        // Navigate to TicketIDPage with transaction details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketIDPage(
              receiptNumber: transactionReference,
              transactionStatus: 'successful',
              userName: userName,
              userPhone: userPhone,
              itemsPurchased: widget.cartItems.map((item) => item['name'].toString()).toList(),
              amountPaid: amount, // Pass the amount paid here
            ),
          ),
        );


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment request sent. Please complete it on your phone.")),
        );
      } else {
        print("Payment failed: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Payment failed. Please try again.")),
        );
      }
    } catch (e) {
      print("Error initiating payment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred. Please try again.")),
      );
    }
  }

  Future<void> _storeTransactionInFirestore(
      String transactionReference,
      String status,
      String username,
      List<Map<String, dynamic>> cartItems,
      double amountPaid,
      ) async {
    final transactionData = {
      'transactionReference': transactionReference,
      'status': status,
      'username': username,
      'itemsPurchased': cartItems.map((item) => item['name']).toList(),
      'amountPaid': amountPaid, // Store amount paid
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('transactions').add(transactionData);
  }


  Future<String> _getMpesaAccessToken(String consumerKey, String consumerSecret) async {
    final authUrl = 'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials';
    String credentials = base64Encode(utf8.encode('$consumerKey:$consumerSecret'));

    final response = await http.get(
      Uri.parse(authUrl),
      headers: {'Authorization': 'Basic $credentials'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['access_token'];
    } else {
      throw Exception("Failed to get access token");
    }
  }

  String _getTimestamp() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
  }

  void _payLater() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order saved for later payment!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('User Details:'),
              _buildUserDetail('Name: $userName'),
              _buildUserDetail('Phone: $userPhone'),
              _buildSectionTitle('Delivery Information:'),
              _buildDeliveryInfo(),
              _buildDeliveryAddressField(),
              _buildSectionTitle('Cart Items:'),
              _buildCartItemsList(),
              _buildTotalAmount(),
              _buildPaymentButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildUserDetail(String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(detail, style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildDeliveryInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery within Nairobi is complimentary. For locations outside of Nairobi, delivery fees may apply based on the distance to the destination.',
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic,color: Colors.grey),
          ),
          SizedBox(height: 8.0),
          Text(
            'Please provide your delivery address below:',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressField() {
    return TextFormField(
      onChanged: (value) {
        setState(() {
          deliveryAddress = value;
        });
      },
      decoration: InputDecoration(
        labelText: 'Enter delivery address',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCartItemsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: widget.cartItems.length,
      itemBuilder: (context, index) {
        final item = widget.cartItems[index];
        return ListTile(
          title: Text(item['name']),
          subtitle: Text('Ksh ${item['price']}',style: TextStyle(fontSize: 16),),
          trailing: Text('Qty: ${item['quantity']}'),
        );
      },
    );
  }

  Widget _buildTotalAmount() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text('Total: Ksh ${widget.totalAmount}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPaymentButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: canPayLater ? _payLater : null,
          child: Text('Pay Later'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange, disabledForegroundColor: Colors.grey.withOpacity(0.38), disabledBackgroundColor: Colors.grey.withOpacity(0.12),
          ),
        ),
        ElevatedButton(
          onPressed: _payNow,
          child: Text('Pay Now',style: TextStyle(color: Colors.white),),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
        ),
      ],
    );
  }
}
