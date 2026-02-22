import 'package:flutter/material.dart';
import 'package:shreelott/screens/helpers/batting_grid_view.dart';

Future<bool> showLogoutDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      // 👈 use ctx
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Header =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(0),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFD32F2F),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          "Log out",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C1C),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(ctx, false), // ✅ FIX
                        borderRadius: BorderRadius.circular(0),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Color(0xFF6B6B6B),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Are you sure you want to log out?",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF222222),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "You’ll be signed out from this device. "
                    "You can sign back in anytime.",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ===== Actions =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ModernBtn(
                        text: "Cancel",
                        textColor: Colors.black,
                        bgColor: Colors.white,
                        width: 200,
                        height: 40,
                        onTap: () {
                          Navigator.pop(ctx, false);
                        },
                      ),
                      // Expanded(
                      //   child: OutlinedButton(
                      //     onPressed: () => Navigator.pop(ctx, false), // ✅ FIX
                      //     style: OutlinedButton.styleFrom(
                      //       padding: const EdgeInsets.symmetric(vertical: 12),
                      //       side: const BorderSide(color: Color(0xFFE0E0E0)),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(0),
                      //       ),
                      //     ),
                      //     child: const Text(
                      //       "Cancel",
                      //       style: TextStyle(
                      //         fontWeight: FontWeight.w600,
                      //         color: Color(0xFF1C1C1C),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      const SizedBox(width: 12),
                      ModernBtn(
                        text: "Logout",
                        bgColor: const Color(0xFFD32F2F),
                        width: 200,
                        height: 40,
                        onTap: () {
                          Navigator.pop(ctx, true);
                        },
                      ),
                      // Expanded(
                      //   child: ElevatedButton(
                      //     onPressed: () => Navigator.pop(ctx, true), // ✅ FIX
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: const Color(0xFFD32F2F),
                      //       foregroundColor: Colors.white,
                      //       padding: const EdgeInsets.symmetric(vertical: 12),
                      //       elevation: 1,
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(0),
                      //       ),
                      //     ),
                      //     child: const Text(
                      //       "Log out",
                      //       style: TextStyle(
                      //         fontWeight: FontWeight.w700,
                      //         letterSpacing: 0.2,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  return result ?? false;
}
