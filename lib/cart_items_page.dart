import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'payment_page.dart';
import 'login_page.dart'; // Make sure to import your login page

class CartItemsPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _incrementQuantity(DocumentSnapshot cartItem) {
    FirebaseFirestore.instance
        .collection('Cart')
        .doc(cartItem.id)
        .update({'quantity': cartItem['quantity'] + 1});
  }

  void _decrementQuantity(DocumentSnapshot cartItem) {
    if (cartItem['quantity'] > 1) {
      FirebaseFirestore.instance
          .collection('Cart')
          .doc(cartItem.id)
          .update({'quantity': cartItem['quantity'] - 1});
    }
  }

  void _removeItemFromCart(DocumentSnapshot cartItem) {
    FirebaseFirestore.instance.collection('Cart').doc(cartItem.id).delete();
  }

  Future<void> _checkout(BuildContext context, List<DocumentSnapshot> cartItems, double totalAmount) async {
    // Check if the user is logged in
    User? user = _auth.currentUser;
    if (user == null) {
      // Show login prompt
      _showLoginPrompt(context);
      return;
    }

    // Create a list to hold the purchase data
    List<Map<String, dynamic>> purchaseData = [];

    for (var item in cartItems) {
      purchaseData.add({
        'name': item['name'],
        'price': item['price'],
        'quantity': item['quantity'],
        'category': item['category'],
        'imageUrl': item['imageUrl'],
      });
    }

    // Save purchase data to Firestore
    await FirebaseFirestore.instance.collection('Purchases').add({
      'items': purchaseData,
      'totalAmount': totalAmount,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Clear the cart after saving purchase data
    await _clearCart();

    // Navigate to the PaymentPage with the purchase data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          cartItems: purchaseData,  // Pass the purchase data
          totalAmount: totalAmount,
        ),
      ),
    );
  }

  Future<void> _clearCart() async {
    User? user = _auth.currentUser;
    if (user != null) {
      // Get all items in the Cart collection for the logged-in user
      QuerySnapshot cartSnapshot = await FirebaseFirestore.instance.collection('Cart').where('userId', isEqualTo: user.uid).get();

      // Delete each item in the cart
      for (var doc in cartSnapshot.docs) {
        await FirebaseFirestore.instance.collection('Cart').doc(doc.id).delete();
      }
    }
  }

  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Please Log In'),
          content: Text('You need to be logged in to proceed with checkout.'),
          actions: [
            TextButton(
              child: Text('Click here to sign in'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to login page
                );
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Cart'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Cart').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Your cart is empty'));
          }

          final cartItems = snapshot.data!.docs;

          double totalAmount = 0;
          for (var item in cartItems) {
            totalAmount += item['price'] * item['quantity'];
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final doc = cartItems[index];
                    final productName = doc['name'];
                    final productImage = doc['imageUrl'];
                    final productPrice = doc['price'];
                    final productQuantity = doc['quantity'];
                    final productCategory = doc['category'];

                    return ListTile(
                      leading: Image.network(productImage, width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(productName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Category: $productCategory'),
                          Text('Ksh $productPrice x $productQuantity'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _decrementQuantity(doc),
                            icon: Icon(Icons.remove_circle_outline),
                          ),
                          Text('$productQuantity'),
                          IconButton(
                            onPressed: () => _incrementQuantity(doc),
                            icon: Icon(Icons.add_circle_outline),
                          ),
                          IconButton(
                            onPressed: () => _removeItemFromCart(doc),
                            icon: Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Ksh $totalAmount',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    _checkout(context, cartItems, totalAmount);  // Call checkout method
                  },
                  child: Text(
                    'Checkout',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: Size(double.infinity, 50),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
