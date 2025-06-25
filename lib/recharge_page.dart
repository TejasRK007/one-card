import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'widgets/upi_pin_dialog.dart';

class RechargePage extends StatefulWidget {
  final String phone, username, email, password;
  final String upiPin;
  final void Function(String)? onPinSet;

  const RechargePage({
    super.key,
    required this.phone,
    required this.username,
    required this.email,
    required this.password,
    required this.upiPin,
    this.onPinSet,
  });

  @override
  State<RechargePage> createState() => _RechargePageState();
}

class _RechargePageState extends State<RechargePage> {
  final TextEditingController _controller = TextEditingController();
  String message = '';

  Future<void> rechargeBalance() async {
    final enteredAmount = double.tryParse(_controller.text.trim());
    if (enteredAmount == null || enteredAmount <= 0) {
      setState(() => message = 'Enter a valid amount');
      return;
    }
    final pinVerified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => UpiPinDialog(
            currentPin: widget.upiPin,
            onPinVerified: (_) {
              Navigator.of(dialogContext).pop(true);
            },
            onPinSet: widget.onPinSet,
          ),
    );
    if (pinVerified == true) {
      try {
        final ref = FirebaseDatabase.instance.ref().child(
          'users/${widget.phone}/balance',
        );
        final snapshot = await ref.get();
        double current =
            snapshot.exists
                ? double.tryParse(snapshot.value.toString()) ?? 0.0
                : 0.0;
        final updated = current + enteredAmount;
        await ref.set(updated);
        if (!mounted) return;
        setState(
          () =>
              message =
                  'Recharged successfully! New Balance: ₹${(double.tryParse(_controller.text.trim()) ?? 0.0).toStringAsFixed(2)}',
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => message = 'Recharge failed: $e');
      }
    } else {
      if (!mounted) return;
      setState(
        () =>
            message =
                message.isNotEmpty
                    ? message
                    : 'Recharge failed. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recharge Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextFormField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter recharge amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: rechargeBalance,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('Recharge'),
            ),
            if (message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 16, color: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
