import 'package:flutter/material.dart';
import 'home_screen.dart';

class LoginPage extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  const LoginPage({super.key, required this.isDarkMode, required this.onThemeChanged});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _upiPinController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureUpiPin = true;
  String? _upiPinError;

  void _login() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final upiPin = _upiPinController.text.trim();

    setState(() { _upiPinError = null; });

    if (upiPin.length != 4) {
      setState(() { _upiPinError = 'UPI PIN must be 4 digits'; });
      return;
    }

    if (username.isNotEmpty &&
        password.isNotEmpty &&
        email.isNotEmpty &&
        phone.isNotEmpty &&
        upiPin.length == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            username: username,
            email: email,
            phone: phone,
            password: password,
            isDarkMode: widget.isDarkMode,
            onThemeChanged: widget.onThemeChanged,
            upiPin: upiPin,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields and enter a 4-digit UPI PIN")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050238),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login to your account',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 40),
                _inputField(
                  label: "Username",
                  icon: Icons.person,
                  controller: _usernameController,
                  isPassword: false,
                ),
                const SizedBox(height: 20),
                _inputField(
                  label: "Email",
                  icon: Icons.email,
                  controller: _emailController,
                  isPassword: false,
                ),
                const SizedBox(height: 20),
                _inputField(
                  label: "Phone Number",
                  icon: Icons.phone,
                  controller: _phoneController,
                  isPassword: false,
                ),
                const SizedBox(height: 20),
                _inputField(
                  label: "Password",
                  icon: Icons.lock,
                  controller: _passwordController,
                  isPassword: true,
                ),
                const SizedBox(height: 20),
                _inputField(
                  label: "UPI PIN (4 digits)",
                  icon: Icons.pin,
                  controller: _upiPinController,
                  isPassword: true,
                  isUpiPin: true,
                  obscureText: _obscureUpiPin,
                  onToggleObscure: () => setState(() => _obscureUpiPin = !_obscureUpiPin),
                  errorText: _upiPinError,
                ),
                const SizedBox(height: 35),
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF050238),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Login", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool isPassword,
    bool isUpiPin = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      keyboardType: isUpiPin ? TextInputType.number : (label == 'Phone Number'
          ? TextInputType.phone
          : (label == 'Email' ? TextInputType.emailAddress : TextInputType.text)),
      maxLength: isUpiPin ? 4 : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white),
        suffixIcon: isUpiPin
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                ),
                onPressed: onToggleObscure,
              )
            : (isPassword && !isUpiPin
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white54,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null),
        filled: true,
        fillColor: Colors.white10,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        counterText: isUpiPin ? '' : null,
        errorText: errorText,
      ),
    );
  }
}
