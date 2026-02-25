import 'package:flutter/material.dart';
import 'package:shreelott/screens/helpers/batting_grid_view.dart';

Future<bool> showLogoutDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (ctx) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E), // 🔥 dark surface
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 30,
                    offset: Offset(0, 15),
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
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFE57373),
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
                            color: Colors.white, // 🔥 white text
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(ctx, false),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.white70,
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
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "You’ll be signed out from this device. "
                        "You can sign back in anytime.",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ===== Actions =====
                  Row(
                    children: [
                      Expanded(
                        child: ModernBtn(
                          text: "Cancel",
                          textColor: Colors.white,
                          bgColor: const Color(0xFF2A2A2A),
                          width: 200,
                          height: 40,
                          onTap: () {
                            Navigator.pop(ctx, false);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ModernBtn(
                          text: "Logout",
                          bgColor: const Color(0xFFD32F2F),
                          width: 200,
                          height: 40,
                          onTap: () {
                            Navigator.pop(ctx, true);
                          },
                        ),
                      ),
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