import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shreelott/screens/helpers/batting_grid_view.dart';
import '../consts/app_colors.dart';

/// Display support dialog with contact information
void showSupportDialog(BuildContext context) {
  const email = 'ShreeLott@gmail.com';
  const phone = '+91 12345 67895';

  void copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(milliseconds: 1500),
        backgroundColor: AppColors.accentGreen,
      ),
    );
  }

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
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

            // Dark overlay
            Positioned.fill(
              child: Container(color: AppColors.overlayBlackTransparent(0.4)),
            ),

            // Main dialog card
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
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
                      // Header with icon and close button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Support icon
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.support_agent_rounded,
                              size: 24,
                              color: AppColors.accentGold,
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Title
                          const Expanded(
                            child: Text(
                              "Support",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),

                          // Close button
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Description
                      const Text(
                        "For any support, please contact us using the details below.",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Email info row
                      _InfoRow(
                        label: 'Email',
                        value: email,
                        onCopy: () => copyToClipboard(email, 'Email'),
                      ),

                      const SizedBox(height: 10),

                      // Phone info row
                      _InfoRow(
                        label: 'Phone',
                        value: phone,
                        onCopy: () => copyToClipboard(phone, 'Phone number'),
                      ),

                      const SizedBox(height: 28),

                      // Close button
                      Align(
                        alignment: Alignment.centerRight,
                        child: ModernBtn(
                          text: "Close",
                          textColor: Colors.black,
                          bgColor: Colors.yellow,
                          width: 100,
                          height: 40,
                          onTap: () {
                            Navigator.pop(context);
                          },
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
    },
  );
}

/// Information row for displaying contact details with copy button
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Label and value
        Expanded(
          child: Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Copy button
        InkWell(
          onTap: onCopy,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.copy_rounded,
              size: 16,
              color: AppColors.accentGold,
            ),
          ),
        ),
      ],
    );
  }
}
