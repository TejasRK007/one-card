import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart'; // ✅ Ensure this path is correct based on your folder structure

class PaymentSuccessPage extends StatefulWidget {
  final double amount;
  final String recipient;
  final String username;
  final String email;
  final String phone;
  final String password;

  const PaymentSuccessPage({
    Key? key,
    required this.amount,
    required this.recipient,
    required this.username,
    required this.email,
    required this.phone,
    required this.password,
  }) : super(key: key);

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: const Icon(Icons.check, color: Colors.white, size: 80),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Transaction Successful!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '₹${widget.amount.toStringAsFixed(2)} paid to',
              style: const TextStyle(fontSize: 20, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            Text(
              widget.recipient,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
              onPressed: () {
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => HomeScreen(
                          username: widget.username,
                          email: widget.email,
                          phone: widget.phone,
                          password: widget.password,
                          isDarkMode: false,
                          onThemeChanged: (v) {},
                          upiPin:
                              '', // TODO: Pass the actual upiPin if available
                        ),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
