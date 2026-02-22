import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../widgets/show_toast_message.dart';
import 'home_screen.dart';

// ================= LOGIN CONSTANTS =================
class LoginConstants {
  // API
  static const String apiBaseUrl = 'https://bid.grocerkings.in/api';
  static const String loginEndpoint = '/login';
  static const String loginUrl = '$apiBaseUrl$loginEndpoint';
  static const int requestTimeout = 30; // seconds

  // Hive boxes
  static const String hiveBoxName = 'app';
  static const String tokenKey = 'token';
  static const String isLoggedInKey = 'isLoggedIn';
  static const String usernameKey = 'username';
  static const String userId = 'user_id';
  static const String passwordKey = 'password';

  // Animation
  static const Duration animationDuration = Duration(milliseconds: 400);
}

// ================= LOGIN COLORS =================
class LoginColors {
  // Background & Gradient
  static const Color gradientStart = Color(0xFF1D2671);
  static const Color gradientEnd = Color(0xFF0F1447);
  static const Color backgroundOverlay = Colors.black;
  static const double overlayOpacity = 0.25;

  // Card & Inputs
  static const Color cardShadowColor = Colors.black;
  static const double shadowOpacity = 0.6;
  static const Color inputFillColor = Color(0xFF2B338F);
  static const Color inputBorderColor = Colors.blueAccent;
  static const Color inputTextColor = Colors.white;
  static const Color inputHintColor = Colors.white54;
  static const Color inputIconColor = Colors.white70;

  // Buttons & Text
  static const Color buttonColor = Color(0xFFFFC107);
  static const Color buttonTextColor = Colors.black;
  static const Color primaryTextColor = Colors.white;
  static const Color secondaryTextColor = Colors.white70;
  static const Color tertiaryTextColor = Colors.white60;

  // Checkbox
  static const Color checkboxColor = Colors.blueAccent;
}

// ================= LOGIN DIMENSIONS =================
class LoginDimensions {
  // Card dimensions
  static const double cardWidth = 520;
  static const double cardBorderRadius = 28;
  static const double cardHorizontalPadding = 50;
  static const double cardVerticalPadding = 20;

  // Input field
  static const double inputBorderRadius = 14;
  static const double inputVerticalPadding = 20;
  static const double inputBorderWidth = 1.5;

  // Button
  static const double buttonHeight = 58;
  static const double buttonBorderRadius = 14;
  static const double buttonElevation = 8;
  static const double progressIndicatorSize = 24;
  static const double progressIndicatorStroke = 2.5;

  // Spacing
  static const double spaceTitleCard = 35;
  static const double spaceInputField = 22;
  static const double spaceCheckboxSection = 18;
  static const double spaceLoginButton = 30;

  // Shadow
  static const double shadowBlurRadius = 50;
  static const double shadowOffsetY = 30;
}

// ================= LOGIN TEXT STYLES =================
class LoginTextStyles {
  static const TextStyle loginTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: LoginColors.primaryTextColor,
  );

  static const TextStyle inputHint = TextStyle(
    color: LoginColors.inputHintColor,
  );

  static const TextStyle inputText = TextStyle(
    color: LoginColors.inputTextColor,
  );

  static const TextStyle rememberMeText = TextStyle(
    color: LoginColors.secondaryTextColor,
    fontSize: 14,
  );

  static const TextStyle forgotPasswordText = TextStyle(
    color: LoginColors.tertiaryTextColor,
    fontSize: 14,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: LoginColors.buttonTextColor,
  );
}

// ================= LOGIN VIEW =================
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
  // Controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State variables
  bool _loading = false;
  bool _rememberMe = true;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================= INITIALIZATION =================
  void _initializeFields() {
    if (widget.isLoggedIn) {
      _usernameController.text = widget.savedUsername;
      _passwordController.text = widget.savedPassword;
      _rememberMe = true;
    }
  }

  // ================= VALIDATION =================
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

  // ================= LOGIN LOGIC =================
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
            onTimeout: () {
              throw TimeoutException('Login request timed out');
            },
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

      // Save login credentials and token
      await _saveLoginData(data['token'], data["user"]["id"].toString());

      showToast("Login successful", context, error: false);

      await Future.delayed(LoginConstants.animationDuration);

      if (!mounted) return;

      _navigateToHome();
    } on TimeoutException {
      setState(() => _loading = false);
      if (mounted) {
        showToast("Request timed out. Please try again.", context);
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        showToast("Network error, Check Your Internet Connection.", context);
      }
    }
  }

  // ================= DATA PERSISTENCE =================
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
      // Clear saved credentials if not remembering
      await box.put(LoginConstants.isLoggedInKey, false);
    }

    await box.put(LoginConstants.tokenKey, token);
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  // ================= TOGGLE PASSWORD VISIBILITY =================
  void _togglePasswordVisibility() {
    setState(() => _passwordVisible = !_passwordVisible);
  }

  // ================= UI BUILDERS =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBackground());
  }

  /// Build main background with overlay and card
  Widget _buildBackground() {
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset("assets/bg_image.png", fit: BoxFit.fill),
        ),

        // Dark overlay
        Positioned.fill(
          child: Container(
            color: LoginColors.backgroundOverlay.withOpacity(
              LoginColors.overlayOpacity,
            ),
          ),
        ),

        // Login card
        Center(
          child: SingleChildScrollView(
            child: Column(
              children: [Image.asset("assets/logo.png"), _buildLoginCard()],
            ),
          ),
        ),
      ],
    );
  }

  /// Build login card with all content
  Widget _buildLoginCard() {
    return Container(
      width: LoginDimensions.cardWidth,
      padding: const EdgeInsets.symmetric(
        horizontal: LoginDimensions.cardHorizontalPadding - 20,
        vertical: LoginDimensions.cardVerticalPadding,
      ),
      decoration: _buildCardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitle(),
          const SizedBox(height: LoginDimensions.spaceTitleCard),
          _buildUsernameField(),
          const SizedBox(height: LoginDimensions.spaceInputField),
          _buildPasswordField(),
          const SizedBox(height: LoginDimensions.spaceCheckboxSection),
          _buildRememberMeRow(),
          const SizedBox(height: LoginDimensions.spaceLoginButton),
          _buildLoginButton(),
        ],
      ),
    );
  }

  /// Build card decoration with gradient and shadow
  BoxDecoration _buildCardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(LoginDimensions.cardBorderRadius),
      gradient: const LinearGradient(
        colors: [LoginColors.gradientStart, LoginColors.gradientEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: LoginColors.cardShadowColor.withOpacity(
            LoginColors.shadowOpacity,
          ),
          blurRadius: LoginDimensions.shadowBlurRadius,
          offset: const Offset(0, LoginDimensions.shadowOffsetY),
        ),
      ],
    );
  }

  /// Build login title
  Widget _buildTitle() {
    return const Text("Login", style: LoginTextStyles.loginTitle);
  }

  /// Build username input field
  Widget _buildUsernameField() {
    return _buildInputField(
      controller: _usernameController,
      hint: "Username",
      icon: Icons.person_outline,
      isPassword: false,
    );
  }

  /// Build password input field with visibility toggle
  Widget _buildPasswordField() {
    return _buildInputField(
      controller: _passwordController,
      hint: "Password",
      icon: Icons.lock_outline,
      isPassword: true,
      showVisibilityToggle: true,
    );
  }

  /// Generic input field builder
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isPassword,
    bool showVisibilityToggle = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !_passwordVisible,
      style: LoginTextStyles.inputText,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: LoginTextStyles.inputHint,
        prefixIcon: Icon(icon, color: LoginColors.inputIconColor),
        suffixIcon: showVisibilityToggle
            ? GestureDetector(
                onTap: _togglePasswordVisibility,
                child: Icon(
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: LoginColors.inputIconColor,
                ),
              )
            : null,
        filled: true,
        fillColor: LoginColors.inputFillColor,
        contentPadding: const EdgeInsets.symmetric(
          vertical: LoginDimensions.inputVerticalPadding,
        ),
        border: _buildInputBorder(),
        focusedBorder: _buildFocusedInputBorder(),
      ),
    );
  }

  /// Build default input border
  OutlineInputBorder _buildInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(LoginDimensions.inputBorderRadius),
      borderSide: BorderSide.none,
    );
  }

  /// Build focused input border
  OutlineInputBorder _buildFocusedInputBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(LoginDimensions.inputBorderRadius),
      borderSide: const BorderSide(
        color: LoginColors.inputBorderColor,
        width: LoginDimensions.inputBorderWidth,
      ),
    );
  }

  /// Build remember me checkbox and forgot password row
  Widget _buildRememberMeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() => _rememberMe = value ?? false);
              },
              activeColor: LoginColors.checkboxColor,
            ),
            const Text("Remember me", style: LoginTextStyles.rememberMeText),
          ],
        ),
        // GestureDetector(
        //   onTap: _handleForgotPassword,
        //   child: const Text(
        //     "Forgot password?",
        //     style: LoginTextStyles.forgotPasswordText,
        //   ),
        // ),
      ],
    );
  }

  /// Build login button with loading state
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: LoginDimensions.buttonHeight,
      child: ElevatedButton(
        onPressed: _loading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: LoginColors.buttonColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              LoginDimensions.buttonBorderRadius,
            ),
          ),
          elevation: LoginDimensions.buttonElevation,
        ),
        child: _loading
            ? _buildLoadingIndicator()
            : const Text("Login", style: LoginTextStyles.buttonText),
      ),
    );
  }

  /// Build loading indicator
  Widget _buildLoadingIndicator() {
    return SizedBox(
      height: LoginDimensions.progressIndicatorSize,
      width: LoginDimensions.progressIndicatorSize,
      child: CircularProgressIndicator(
        strokeWidth: LoginDimensions.progressIndicatorStroke,
        color: LoginColors.buttonTextColor,
      ),
    );
  }

  // ================= EVENT HANDLERS =================
  void _handleForgotPassword() {
    showToast("Forgot password feature coming soon", context);
    // TODO: Implement forgot password functionality
  }
}
