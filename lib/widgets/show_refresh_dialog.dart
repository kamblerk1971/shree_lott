import 'package:flutter/material.dart';

Future<bool> showRefreshDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
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
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(0),
                        ),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF1976D2),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          "Refresh data",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C1C),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context, false),
                        borderRadius: BorderRadius.circular(20),
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

                  // ===== Message =====
                  const Text(
                    "Refresh home data?",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF222222),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "This will reload the latest draw time, terminal details, and transactions.",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // ===== Actions =====
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            side: const BorderSide(
                              color: Color(0xFFE0E0E0),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C1C1C),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(0),
                            ),
                          ),
                          child: const Text(
                            "Refresh",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
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
