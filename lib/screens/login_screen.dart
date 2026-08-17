import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../widgets/show_toast_message.dart';
import 'home_screen.dart';

class LoginConstants {
  static const String apiBaseUrl = 'https://bid.funmitra.in/api';
  static const String loginEndpoint = '/login';
  static const String loginUrl = '$apiBaseUrl$loginEndpoint';
  static const int requestTimeout = 30;
  static const String hiveBoxName = 'app';
  static const String tokenKey = 'token';
  static const String isLoggedInKey = 'isLoggedIn';
  static const String usernameKey = 'username';
  static const String userId = 'user_id';
  static const String passwordKey = 'password';
  static const Duration animationDuration = Duration(milliseconds: 400);
}

class LoginView extends StatefulWidget {
  final bool isLoggedIn;
  final String savedUsername;
  final String savedPassword;

  const LoginView({
    super.key,
    this.isLoggedIn = false,
    this.savedUsername = '',
    this.savedPassword = '',
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  bool _rememberMe = true;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.isLoggedIn) {
      _usernameController.text = widget.savedUsername;
      _passwordController.text = widget.savedPassword;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty) {
      showToast("Username is required", context);
      return false;
    }
    if (password.isEmpty) {
      showToast("Password is required", context);
      return false;
    }
    if (username.length < 3) {
      showToast("Username must be at least 3 characters", context);
      return false;
    }
    if (password.length < 6) {
      showToast("Password must be at least 6 characters", context);
      return false;
    }
    return true;
  }

  Future<void> _login() async {
    if (!_validate()) return;
    setState(() => _loading = true);
    try {
      final response = await http
          .post(
            Uri.parse(LoginConstants.loginUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "username": _usernameController.text.trim(),
              "password": _passwordController.text.trim(),
            }),
          )
          .timeout(
            const Duration(seconds: LoginConstants.requestTimeout),
            onTimeout: () => throw TimeoutException('Login request timed out'),
          );

      setState(() => _loading = false);
      if (!mounted) return;

      if (response.statusCode != 200) {
        showToast("Server error (${response.statusCode})", context);
        return;
      }

      final data = jsonDecode(response.body);
      if (data['status'] != true) {
        showToast(data['message'] ?? "Login failed", context);
        return;
      }

      await _saveLoginData(data['token'], data["user"]["id"].toString());
      showToast("Login successful", context, error: false);
      await Future.delayed(LoginConstants.animationDuration);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on TimeoutException {
      setState(() => _loading = false);
      if (mounted) showToast("Request timed out. Please try again.", context);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted)
        showToast("Network error, Check Your Internet Connection.", context);
    }
  }

  Future<void> _saveLoginData(String token, String id) async {
    final box = Hive.box(LoginConstants.hiveBoxName);
    if (_rememberMe) {
      await box.put(LoginConstants.isLoggedInKey, true);
      await box.put(
        LoginConstants.usernameKey,
        _usernameController.text.trim(),
      );
      await box.put(
        LoginConstants.passwordKey,
        _passwordController.text.trim(),
      );
      await box.put(LoginConstants.userId, id);
    } else {
      await box.put(LoginConstants.isLoggedInKey, false);
    }
    await box.put(LoginConstants.tokenKey, token);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background image fills entire screen ──
          Image.asset('assets/image_bg.jpeg', fit: BoxFit.fill),

          // ── Card centered on top of image ──
          Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    SizedBox(height: 50),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        border: Border.all(
                          color: const Color(0xFFB8860B),
                          width: 6,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Username row
                            _fieldRow(
                              label: 'Username:',
                              controller: _usernameController,
                              isPassword: false,
                            ),
                            const SizedBox(height: 14),
                            // Password row
                            _fieldRow(
                              label: 'Password:',
                              controller: _passwordController,
                              isPassword: true,
                            ),
                            const SizedBox(height: 20),
                            // Login button
                            _loginButton(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldRow({
    required String label,
    required TextEditingController controller,
    required bool isPassword,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A0A00),
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: controller,
              obscureText: isPassword && !_passwordVisible,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 9,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: Color(0xFFB8860B)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(color: Color(0xFFB8860B)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: const BorderSide(
                    color: Color(0xFF7A5000),
                    width: 1.8,
                  ),
                ),
                suffixIcon: isPassword
                    ? GestureDetector(
                        onTap: () => setState(
                          () => _passwordVisible = !_passwordVisible,
                        ),
                        child: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          size: 16,
                          color: Colors.black54,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _loginButton() {
    return Container(
      width: 130,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFDE3A), Color(0xFFE09000)],
        ),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF7A5000), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: _loading ? null : _login,
          child: Center(
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black87,
                    ),
                  )
                : const Text(
                    'LOGIN',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      letterSpacing: 1.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
