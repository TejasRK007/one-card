import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'upi_payment_page.dart';

class QRScanPage extends StatefulWidget {
  final String username;
  final String email;
  final String phone;
  final String password;
  final String upiPin;

  const QRScanPage({
    Key? key,
    required this.username,
    required this.email,
    required this.phone,
    required this.password,
    required this.upiPin,
  }) : super(key: key);

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  String scannedData = "Scan a QR code";
  bool isScanning = true;

  void _onDetect(BarcodeCapture capture) async {
    if (!isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code != null) {
      setState(() {
        scannedData = code;
        isScanning = false;
      });

      final cardId = code;
      final timestamp = DateFormat(
        'yyyy-MM-dd HH:mm:ss',
      ).format(DateTime.now());

      final scanData = {'cardId': cardId, 'data': code, 'timestamp': timestamp};

      try {
        final db = FirebaseDatabase.instance.ref();
        await db.child('scans').push().set(scanData);

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => UPIPaymentPage(
                  cardId: cardId,
                  scannedData: code,
                  timestamp: timestamp,
                  username: widget.username,
                  email: widget.email,
                  phone: widget.phone,
                  password: widget.password,
                  upiPin: widget.upiPin,
                ),
          ),
        ).then((_) {
          setState(() {
            isScanning = true; // re-enable scanning after returning
          });
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to log scan: $e")));
        setState(() {
          isScanning = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("QR Scanner")),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(onDetect: _onDetect),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.greenAccent, width: 4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                scannedData,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
