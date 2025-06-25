import 'package:flutter/material.dart';
import 'payment_success_page.dart';
import 'widgets/upi_pin_dialog.dart';

class TapPaymentPage extends StatefulWidget {
  final String upiPin;
  final String username;
  final String email;
  final String phone;
  final String password;
  final void Function(String)? onPinSet;

  const TapPaymentPage({
    super.key,
    required this.upiPin,
    required this.username,
    required this.email,
    required this.phone,
    required this.password,
    this.onPinSet,
  });

  @override
  _TapPaymentPageState createState() => _TapPaymentPageState();
}

class _TapPaymentPageState extends State<TapPaymentPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'Transport';
  double? _amount;
  final _pinController = TextEditingController();

  final List<String> _categories = [
    'Transport',
    'Food',
    'Mobile Recharge',
    'WiFi Recharge',
    'Shopping',
  ];

  void _showPinDialogAndPay() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final pinVerified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => UpiPinDialog(
              currentPin: widget.upiPin,
              onPinVerified: (_) {
                try {
                  Navigator.of(dialogContext).pop(true);
                } catch (e) {
                  Navigator.of(dialogContext).pop(false);
                }
              },
              onPinSet: widget.onPinSet,
            ),
      );
      if (pinVerified == true) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => PaymentSuccessPage(
                  amount: _amount!,
                  recipient: _selectedCategory,
                  username: widget.username,
                  email: widget.email,
                  phone: widget.phone,
                  password: widget.password,
                ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items:
                    _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                onSaved: (value) => _amount = double.parse(value!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _showPinDialogAndPay,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Proceed to Pay'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
