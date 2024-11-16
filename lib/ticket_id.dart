import 'dart:io';
import 'package:cakesbydarq/home_page.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart' show rootBundle;

class TicketIDPage extends StatefulWidget {
  final String receiptNumber;
  final String transactionStatus;
  final String userName;
  final String userPhone;
  final List<String> itemsPurchased;
  final double amountPaid;

  TicketIDPage({
    required this.receiptNumber,
    required this.transactionStatus,
    required this.userName,
    required this.userPhone,
    required this.itemsPurchased,
    required this.amountPaid,
  });

  @override
  _TicketIDPageState createState() => _TicketIDPageState();
}

class _TicketIDPageState extends State<TicketIDPage> {
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt Details'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Cakesbydarq'), // Company name at the top
            _buildSectionTitle('Receipt Number:'),
            _buildDetailText(widget.receiptNumber),
            _buildSectionTitle('Transaction Status:'),
            _buildDetailText(widget.transactionStatus),
            _buildSectionTitle('User Information:'),
            _buildDetailText('Name: ${widget.userName}'),
            _buildDetailText('Phone: ${widget.userPhone}'),
            _buildSectionTitle('Items Purchased:'),
            _buildItemsList(),
            _buildSectionTitle('Amount Paid:'),
            _buildDetailText('Ksh${widget.amountPaid.toStringAsFixed(2)}'),
            _buildSectionTitle('Thank You!'),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Text(
                'Your order has been received and will be processed shortly.',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
            SizedBox(height: 20),
            _isDownloading
                ? Center(child: CircularProgressIndicator())
                : Center(
              child: ElevatedButton(
                onPressed: () => _generatePDF(),
                child: Text('Download Receipt as PDF'),
              ),
            ),
          ],
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

  Widget _buildDetailText(String detail) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Text(
        detail,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: widget.itemsPurchased.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Text(
            widget.itemsPurchased[index],
            style: TextStyle(fontSize: 16),
          ),
        );
      },
    );
  }

  Future<void> _generatePDF() async {
    PermissionStatus status = await Permission.storage.request();

    if (status.isGranted) {
      setState(() {
        _isDownloading = true;
      });

      final pdf = pw.Document();
      final logo = pw.MemoryImage(
        (await rootBundle.load('assets/icon.png')).buffer.asUint8List(),
      );

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) =>
              pw.Stack(
                children: [
                  pw.Center(
                    child: pw.Opacity(
                      opacity: 0.2,
                      child: pw.Image(logo, width: 200, height: 200),
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Cakesbydarq', style: pw.TextStyle(fontSize: 24)),
                      pw.SizedBox(height: 10),
                      pw.Text('Receipt Number: ${widget.receiptNumber}',
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                      pw.Text(
                          'Transaction Status: ${widget.transactionStatus}'),
                      pw.SizedBox(height: 10),
                      pw.Text('User Information:'),
                      pw.Text('Name: ${widget.userName}'),
                      pw.Text('Phone: ${widget.userPhone}'),
                      pw.SizedBox(height: 10),
                      pw.Text('Items Purchased:'),
                      pw.Bullet(text: widget.itemsPurchased.join(', ')),
                      pw.SizedBox(height: 10),
                      pw.Text(
                          'Amount Paid: Ksh${widget.amountPaid.toStringAsFixed(
                              2)}'),
                      pw.SizedBox(height: 20),
                      pw.Text('Thank You for Your Order!',
                          style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                ],
              ),
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/receipt_${widget.receiptNumber}.pdf';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _isDownloading = false;
      });

      _showResultDialog('Download Successful!',
          'The PDF receipt has been saved successfully.');
      await _openFile(filePath);
    } else {
      setState(() {
        _isDownloading = false;
      });
      _showResultDialog('Download Failed',
          'Please enable storage permissions and try again.');
    }
  }

  Future<void> _openFile(String filePath) async {
    final result = await OpenFile.open(filePath);
    if (result.type == ResultType.done) {
      print("File opened successfully.");
    } else {
      print("Failed to open the file.");
    }
  }

  void _showResultDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => HomePage()),
                      (Route<
                      dynamic> route) => false, // Remove all previous routes
                );
              },
            ),
          ],
        );
      },
    );
  }
}
