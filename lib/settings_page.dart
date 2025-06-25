import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'upi_pin_page.dart';
import 'link_card_page.dart';
import 'widgets/upi_pin_dialog.dart';

class SettingsPage extends StatefulWidget {
  final String phone, username, email, password;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final String? upiPin;
  final Function(String) onPinSet;
  final String? cardUID;
  final Function(String) onCardLinked;

  const SettingsPage({
    super.key,
    required this.phone,
    required this.username,
    required this.email,
    required this.password,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.upiPin,
    required this.onPinSet,
    required this.cardUID,
    required this.onCardLinked,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _changeTheme(bool value) {
    setState(() => isDarkMode = value);
    widget.onThemeChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Update Profile'),
            onTap: () {
              // TODO: Implement profile update
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile update coming soon!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Change Password'),
            onTap: () {
              // TODO: Implement password change
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password change coming soon!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: Text(
              widget.cardUID != null ? 'Card Linked' : 'Link RFID Card',
            ),
            subtitle: widget.cardUID != null ? Text(widget.cardUID!) : null,
            onTap:
                widget.cardUID != null
                    ? null // Already linked
                    : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => LinkCardPage(
                                phone: widget.phone,
                                onCardLinked: widget.onCardLinked,
                              ),
                        ),
                      );
                    },
          ),
          ListTile(
            leading: const Icon(Icons.pin),
            title: Text(
              widget.upiPin != null ? 'Reset UPI PIN' : 'Set UPI PIN',
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => UpiPinPage(
                        currentPin: widget.upiPin,
                        onPinSet: widget.onPinSet,
                      ),
                ),
              );
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.pin),
            label: const Text('Change UPI PIN'),
            onPressed: () async {
              final newPin = await showDialog<String>(
                context: context,
                builder:
                    (context) => UpiPinDialog(
                      currentPin: widget.upiPin,
                      onPinVerified: (pin) {
                        Navigator.of(context).pop(pin);
                      },
                      onPinSet: widget.onPinSet,
                    ),
              );
              if (newPin != null && newPin.length == 4) {
                widget.onPinSet(newPin);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('UPI PIN changed successfully!'),
                  ),
                );
              }
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            value: isDarkMode,
            onChanged: _changeTheme,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
