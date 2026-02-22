import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shreelott/screens/helpers/batting_grid_view.dart';
import '../consts/app_colors.dart';

Future<bool> showChangePasswordDialog(
  BuildContext context, {
  required String baseUrl,
  required String token,
}) async {
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool isLoading = false;
  bool showCurrent = false;
  bool showNew = false;
  bool showConfirm = false;

  String? responseMessage;
  Color responseColor = AppColors.textSecondary;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                // Background image
                // Positioned.fill(
                //   child: Image.asset(
                //     "assets/bg_image_1.png",
                //     fit: BoxFit.cover,
                //     errorBuilder: (context, error, stackTrace) {
                //       return Container(
                //         decoration: BoxDecoration(
                //           gradient: AppColors.premiumDarkGradient,
                //         ),
                //       );
                //     },
                //   ),
                // ),

                // Dark overlay for depth
                Positioned.fill(
                  child: Container(
                    color: AppColors.overlayBlackTransparent(0.3),
                  ),
                ),

                // Main dialog card
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),

                        // Premium radial gradient
                        gradient: RadialGradient(
                          center: const Alignment(0.3, -0.3),
                          radius: 1.2,
                          colors: [
                            AppColors.primaryMedium.withOpacity(0.95),
                            AppColors.primaryDarker,
                          ],
                          stops: const [0.0, 1.0],
                        ),

                        // Layered shadows
                        boxShadow: AppColors.premiumCardShadow,

                        // Subtle border
                        border: Border.all(
                          color: AppColors.borderLight.withOpacity(0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with close button
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  "Change your password",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.pop(context, false),
                                child: const Icon(
                                  Icons.close,
                                  size: 20,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          // Description
                          const Text(
                            "For your security, please enter your current password and choose a new one.",
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.45,
                              color: AppColors.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Current password field
                          _passwordField(
                            label: "Current password",
                            controller: currentCtrl,
                            isVisible: showCurrent,
                            onToggle: () =>
                                setState(() => showCurrent = !showCurrent),
                          ),

                          const SizedBox(height: 14),

                          // New password field with generate button
                          _passwordField(
                            label: "New password",
                            controller: newCtrl,
                            isVisible: showNew,
                            onToggle: () => setState(() => showNew = !showNew),
                            suffix: TextButton(
                              onPressed: () {
                                final pwd = _generatePassword();
                                setState(() {
                                  newCtrl.text = pwd;
                                  confirmCtrl.text = pwd;
                                  responseMessage = "Generated password: $pwd";
                                  responseColor = AppColors.accentGreen;
                                });
                              },
                              child: const Text(
                                "Generate",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentGold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Confirm password field
                          _passwordField(
                            label: "Confirm new password",
                            controller: confirmCtrl,
                            isVisible: showConfirm,
                            onToggle: () =>
                                setState(() => showConfirm = !showConfirm),
                          ),

                          const SizedBox(height: 16),

                          // Response message
                          if (responseMessage != null)
                            Text(
                              responseMessage!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: responseColor,
                                height: 1.4,
                              ),
                            ),

                          const SizedBox(height: 20),

                          // Action buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Cancel button


                              // Expanded(
                              //   child: TextButton(
                              //     onPressed: () =>
                              //         Navigator.pop(context, false),
                              //     child: const Text(
                              //       "Cancel",
                              //       style: TextStyle(
                              //         fontSize: 15,
                              //         fontWeight: FontWeight.w600,
                              //         color: AppColors.textPrimary,
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              // Update button
                              ModernBtn(
                                text: isLoading
                                    ? "Please Wait..."
                                    : "Update Password",
                                bgColor: isLoading ? Colors.grey : Colors.green,
                                width: 150,
                                height: 40,
                                onTap: () async {
                                  if (isLoading)
                                    return; // 🔥 prevent multiple taps

                                  setState(() {
                                    responseMessage = null;
                                  });

                                  // Validation checks
                                  if (currentCtrl.text.isEmpty ||
                                      newCtrl.text.isEmpty ||
                                      confirmCtrl.text.isEmpty) {
                                    setState(() {
                                      responseMessage =
                                          "All fields are required";
                                      responseColor = const Color(0xFFFF385C);
                                    });
                                    return;
                                  }

                                  if (newCtrl.text.length != 8) {
                                    setState(() {
                                      responseMessage =
                                          "Password must be exactly 8 characters";
                                      responseColor = const Color(0xFFFF385C);
                                    });
                                    return;
                                  }

                                  if (currentCtrl.text == newCtrl.text) {
                                    setState(() {
                                      responseMessage =
                                          "New password must be different from current password";
                                      responseColor = const Color(0xFFFF385C);
                                    });
                                    return;
                                  }

                                  if (newCtrl.text != confirmCtrl.text) {
                                    setState(() {
                                      responseMessage =
                                          "Passwords do not match";
                                      responseColor = const Color(0xFFFF385C);
                                    });
                                    return;
                                  }

                                  setState(() => isLoading = true);

                                  final apiResult = await _changePasswordApi(
                                    baseUrl: baseUrl,
                                    token: token,
                                    current: currentCtrl.text,
                                    newPass: newCtrl.text,
                                    confirm: confirmCtrl.text,
                                  );

                                  // if (!mounted) return;

                                  setState(() => isLoading = false);

                                  if (apiResult.success) {
                                    setState(() {
                                      responseMessage = apiResult.message;
                                      responseColor = AppColors.accentGreen;
                                    });

                                    await Future.delayed(
                                      const Duration(milliseconds: 900),
                                    );

                                    Navigator.pop(context, true);
                                  } else {
                                    setState(() {
                                      responseMessage = apiResult.message;
                                      responseColor = apiResult.isUnauthorized
                                          ? const Color(0xFFFF385C)
                                          : AppColors.accentYellow;
                                    });
                                  }
                                },
                              ),

                              ModernBtn(
                                text: "Close",
                                textColor: Colors.black,
                                bgColor: Colors.yellow,
                                width: 100,
                                height: 40,
                                onTap: () {
                                  Navigator.pop(context, false);
                                },
                              ),

                              // Expanded(
                              //   child: ElevatedButton(
                              //     onPressed:
                              //     isLoading
                              //         ? null
                              //         : () async {
                              //             setState(() {
                              //               responseMessage = null;
                              //             });
                              //
                              //             // Validation checks
                              //             if (currentCtrl.text.isEmpty ||
                              //                 newCtrl.text.isEmpty ||
                              //                 confirmCtrl.text.isEmpty) {
                              //               setState(() {
                              //                 responseMessage =
                              //                     "All fields are required";
                              //                 responseColor = const Color(
                              //                   0xFFFF385C,
                              //                 );
                              //               });
                              //               return;
                              //             }
                              //
                              //             if (newCtrl.text.length != 8) {
                              //               setState(() {
                              //                 responseMessage =
                              //                     "Password must be exactly 8 characters";
                              //                 responseColor = const Color(
                              //                   0xFFFF385C,
                              //                 );
                              //               });
                              //               return;
                              //             }
                              //
                              //             if (currentCtrl.text ==
                              //                 newCtrl.text) {
                              //               setState(() {
                              //                 responseMessage =
                              //                     "New password must be different from current password";
                              //                 responseColor = const Color(
                              //                   0xFFFF385C,
                              //                 );
                              //               });
                              //               return;
                              //             }
                              //
                              //             if (newCtrl.text !=
                              //                 confirmCtrl.text) {
                              //               setState(() {
                              //                 responseMessage =
                              //                     "Passwords do not match";
                              //                 responseColor = const Color(
                              //                   0xFFFF385C,
                              //                 );
                              //               });
                              //               return;
                              //             }
                              //
                              //             setState(() => isLoading = true);
                              //
                              //             final apiResult =
                              //                 await _changePasswordApi(
                              //                   baseUrl: baseUrl,
                              //                   token: token,
                              //                   current: currentCtrl.text,
                              //                   newPass: newCtrl.text,
                              //                   confirm: confirmCtrl.text,
                              //                 );
                              //
                              //             setState(() => isLoading = false);
                              //
                              //             if (apiResult.success) {
                              //               setState(() {
                              //                 responseMessage =
                              //                     apiResult.message;
                              //                 responseColor =
                              //                     AppColors.accentGreen;
                              //               });
                              //               await Future.delayed(
                              //                 const Duration(milliseconds: 900),
                              //               );
                              //               Navigator.pop(context, true);
                              //             } else {
                              //               setState(() {
                              //                 responseMessage =
                              //                     apiResult.message;
                              //                 responseColor =
                              //                     apiResult.isUnauthorized
                              //                     ? const Color(0xFFFF385C)
                              //                     : AppColors.accentYellow;
                              //               });
                              //             }
                              //           },
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: AppColors.accentGreen,
                              //       disabledBackgroundColor: AppColors
                              //           .accentGreen
                              //           .withOpacity(0.6),
                              //       foregroundColor: AppColors.textPrimary,
                              //       elevation: 8,
                              //       shadowColor: AppColors.accentGreen
                              //           .withOpacity(0.5),
                              //       padding: const EdgeInsets.symmetric(
                              //         vertical: 14,
                              //       ),
                              //       shape: RoundedRectangleBorder(
                              //         borderRadius: BorderRadius.circular(8),
                              //       ),
                              //     ),
                              //     child: isLoading
                              //         ? const SizedBox(
                              //             height: 18,
                              //             width: 18,
                              //             child: CircularProgressIndicator(
                              //               strokeWidth: 2,
                              //               valueColor:
                              //                   AlwaysStoppedAnimation<Color>(
                              //                     AppColors.textPrimary,
                              //                   ),
                              //             ),
                              //           )
                              //         : const Text(
                              //             "Update password",
                              //             style: TextStyle(
                              //               fontSize: 15,
                              //               fontWeight: FontWeight.w700,
                              //             ),
                              //           ),
                              //   ),
                              // ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  // Cleanup
  currentCtrl.dispose();
  newCtrl.dispose();
  confirmCtrl.dispose();

  return result ?? false;
}

/// Password input field with visibility toggle
Widget _passwordField({
  required String label,
  required TextEditingController controller,
  required bool isVisible,
  required VoidCallback onToggle,
  Widget? suffix,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Label
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 8),

      // Input field container
      Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.borderLight.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: AppColors.primaryDarker.withOpacity(0.3),
        ),
        child: TextField(
          controller: controller,
          obscureText: !isVisible,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          cursorColor: AppColors.accentGold,
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            hintText: label,
            hintStyle: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
              fontSize: 14,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Custom suffix button (Generate)
                if (suffix != null) suffix,

                // Visibility toggle button
                IconButton(
                  icon: Icon(
                    isVisible ? Icons.visibility : Icons.visibility_off,
                    size: 20,
                    color: AppColors.borderLight.withOpacity(0.6),
                  ),
                  onPressed: onToggle,
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

/// Generate a random 8-character password
String _generatePassword() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rand = Random.secure();
  return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
}

/// API response model
class ApiResult {
  final bool success;
  final String message;
  final bool isUnauthorized;

  ApiResult({
    required this.success,
    required this.message,
    this.isUnauthorized = false,
  });
}

/// API call to change password
Future<ApiResult> _changePasswordApi({
  required String baseUrl,
  required String token,
  required String current,
  required String newPass,
  required String confirm,
}) async {
  try {
    final response = await http.post(
      Uri.parse("$baseUrl/change-password"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "current_password": current,
        "new_password": newPass,
        "new_password_confirmation": confirm,
      }),
    );

    final data = jsonDecode(response.body);

    // Check for unauthorized access
    if (response.statusCode == 401 || data["message"] == "Unauthorized") {
      return ApiResult(
        success: false,
        isUnauthorized: true,
        message: "Please login again to change password",
      );
    }

    // Check for successful response
    if (response.statusCode == 200 && data["status"] == true) {
      return ApiResult(
        success: true,
        message: data["message"] ?? "Password updated successfully",
      );
    }

    // Return error message from API
    return ApiResult(
      success: false,
      message: data["message"] ?? "Unable to change password",
    );
  } catch (_) {
    return ApiResult(
      success: false,
      message: "Network error. Please try again.",
    );
  }
}
