import 'package:flutter/material.dart';

class UpiPinDialog extends StatefulWidget {
  final String? currentPin;
  final void Function(String) onPinVerified;
  final void Function(String)? onPinSet;

  const UpiPinDialog({
    super.key,
    required this.currentPin,
    required this.onPinVerified,
    this.onPinSet,
  });

  @override
  State<UpiPinDialog> createState() => _UpiPinDialogState();
}

class _UpiPinDialogState extends State<UpiPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  String? _errorText;
  bool _isSettingPin = false;
  bool _obscurePin = true;
  int _retryCount = 0;
  bool _locked = false;
  DateTime? _lockEnd;

  @override
  void initState() {
    super.initState();
    _isSettingPin = widget.currentPin == null;
  }

  void _handleSubmit() {
    if (_locked) return;
    final pin = _pinController.text.trim();
    if (pin.length != 4) {
      setState(() => _errorText = 'PIN must be 4 digits');
      return;
    }
    if (_isSettingPin) {
      final confirmPin = _confirmPinController.text.trim();
      if (pin != confirmPin) {
        setState(() => _errorText = 'PINs do not match');
        return;
      }
      widget.onPinSet?.call(pin);
      Navigator.of(context).pop();
    } else {
      if (pin == widget.currentPin) {
        widget.onPinVerified(pin);
        Navigator.of(context).pop();
      } else {
        setState(() {
          _retryCount++;
          _errorText = 'Incorrect PIN';
          if (_retryCount >= 3) {
            _locked = true;
            _lockEnd = DateTime.now().add(const Duration(seconds: 30));
            Future.delayed(const Duration(seconds: 30), () {
              if (mounted) setState(() { _locked = false; _retryCount = 0; _errorText = null; });
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isSettingPin ? 'Set UPI PIN' : 'Enter UPI PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: _obscurePin,
            maxLength: 4,
            enabled: !_locked,
            decoration: InputDecoration(
              labelText: 'UPI PIN',
              counterText: '',
              errorText: _locked ? 'Too many attempts. Try again in 30s.' : _errorText,
              suffixIcon: IconButton(
                icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
                tooltip: _obscurePin ? 'Show PIN' : 'Hide PIN',
              ),
            ),
          ),
          if (_isSettingPin)
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: _obscurePin,
              maxLength: 4,
              enabled: !_locked,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                counterText: '',
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _locked ? null : _handleSubmit,
          child: Text(_isSettingPin ? 'Set PIN' : 'Verify'),
        ),
      ],
    );
  }
} 