import 'package:flutter/material.dart';
import 'package:shreelott/consts/app_colors.dart';
import 'package:shreelott/controller/home_controller.dart';
import 'package:shreelott/screens/helpers/batting_grid_view.dart';
import 'package:shreelott/service/ticket_print_service.dart';

/// Premium Color Constants for Account Details Card
class AccountDetailsColors {
  static const Color primaryDarkBlue = Color(0xFF1e1860);
  static const Color primaryMediumBlue = Color(0xFF4556cc);
  static const Color primaryDarkerBlue = Color(0xFF1f114c);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color greenButton = Color(0xFF00C853);
  static const Color yellowButton = Color(0xFFFDD835);
  static const Color textWhite = Colors.white;
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textDark = Color(0xFF212121);
  static const Color borderLight = Color(0xFFFFFFFF);
  static const Color overlayBlack = Color(0xFF000000);
  static const Color bgGradientLight = Color(0xFF1e1860);
  static const Color bgGradientDark = Color(0xFF1f114c);
  static const Color shadowColor = Color(0xFF0D0D1F);
}

// ─────────────────────────────────────────────────────────────
// DIALOG WIDGET — uses Dialog instead of Scaffold
// ─────────────────────────────────────────────────────────────
class AccountDetailsDialog extends StatefulWidget {
  /// Initial data map — must contain at minimum:
  /// "userId" : String
  /// "walletBalance" : String
  /// The widget will fetch and merge:
  /// "todaySale", "todayWinning", "todayCommission", "settlement"
  final Map<String, dynamic> data;
  final String? backgroundImage;
  final VoidCallback? onClose;

  const AccountDetailsDialog({
    Key? key,
    required this.data,
    this.backgroundImage,
    this.onClose,
  }) : super(key: key);

  @override
  State<AccountDetailsDialog> createState() => _AccountDetailsDialogState();
}

class _AccountDetailsDialogState extends State<AccountDetailsDialog> {
  bool _loading = true;
  String? _error;

  // Merged data: starts with what was passed in, report fields added on load
  late Map<String, dynamic> _displayData;

  @override
  void initState() {
    super.initState();
    // Seed display data with what we already have (userId, walletBalance)
    _displayData = Map<String, dynamic>.from(widget.data);
    _fetchReport();
  }

  // ── API ────────────────────────────────────────────────────
  Future<void> _fetchReport() async {
    HomeController controller = HomeController();
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final today =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final res = await controller.fetchReport(from: today, to: today);

      if (res == null || !res.status) {
        throw Exception("Report API returned failure status");
      }

      final total = res.reportData.total;

      // Merge report fields into display data
      _displayData = {
        ..._displayData,
        "todaySale": total.totalLoad.toStringAsFixed(2),
        "todayWinning": total.winning.toStringAsFixed(2),
        "todayCommission": total.commission.toStringAsFixed(2),
        "settlement": total.endPoint.toStringAsFixed(2),
      };
    } catch (e) {
      _error = "Failed to load report data.";
      debugPrint("AccountDetailsDialog._fetchReport error: $e");
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _closeDialog() {
    widget.onClose?.call();
    Navigator.of(context).pop();
  }

  // ── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: RadialGradient(
              center: const Alignment(0.3, -0.3),
              radius: 1.2,
              colors: [
                AccountDetailsColors.primaryMediumBlue.withOpacity(0.95),
                AccountDetailsColors.primaryDarkerBlue,
              ],
              stops: const [0.0, 1.0],
            ),
            border: Border.all(
              color: AccountDetailsColors.borderLight.withOpacity(0.12),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Account Details",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: AccountDetailsColors.textWhite,
                      letterSpacing: 0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: _closeDialog,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AccountDetailsColors.borderLight.withOpacity(
                          0.1,
                        ),
                        border: Border.all(
                          color: AccountDetailsColors.borderLight.withOpacity(
                            0.2,
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AccountDetailsColors.textWhite,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),

              // Divider
              const SizedBox(height: 18),
              Container(
                height: 1.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AccountDetailsColors.borderLight.withOpacity(0),
                      AccountDetailsColors.borderLight.withOpacity(0.3),
                      AccountDetailsColors.borderLight.withOpacity(0),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // ── Static fields (always available) ────────────
              _buildDetailRow(
                label: "User Id",
                value: _displayData["userId"]?.toString() ?? "—",
                valueColor: AccountDetailsColors.goldAccent,
                isHighlight: true,
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                label: "Wallet Balance",
                value: "₹ ${_displayData["walletBalance"] ?? "0"}",
                valueColor: AccountDetailsColors.goldAccent,
                isHighlight: true,
                isBold: true,
              ),
              const SizedBox(height: 14),

              // ── Report fields (loading / error / data) ────────
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                            AccountDetailsColors.goldAccent,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "Loading Account Summary…",
                        style: TextStyle(
                          color: AccountDetailsColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFFF5252),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _fetchReport,
                        child: const Text(
                          "Tap to retry",
                          style: TextStyle(
                            color: AccountDetailsColors.goldAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _buildDetailRow(
                  label: "Today Sale",
                  value: _displayData["todaySale"]?.toString() ?? "0",
                  valueColor: AccountDetailsColors.textWhite,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  label: "Today Winning Amount",
                  value: _displayData["todayWinning"]?.toString() ?? "0",
                  valueColor: AccountDetailsColors.textWhite,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  label: "Today Commission",
                  value: _displayData["todayCommission"]?.toString() ?? "0",
                  valueColor: AccountDetailsColors.textWhite,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  label: "Settlement",
                  value: _displayData["settlement"]?.toString() ?? "0",
                  valueColor: AccountDetailsColors.textWhite,
                ),
              ],

              const SizedBox(height: 28),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ModernBtn(
                    text: "Print",
                    bgColor: Colors.green,
                    width: 100,
                    height: 40,
                    onTap: () {
                      TicketPrintService.printAccountSummary(
                        context,
                        _displayData,
                      );
                    },
                  ),
                  // Expanded(
                  //   child: _buildButton(
                  //     label: "Print",
                  //     backgroundColor: AccountDetailsColors.greenButton,
                  //     textColor: AccountDetailsColors.textWhite,
                  //     onPressed: () {
                  //       TicketPrintService.printAccountSummary(
                  //         context,
                  //         _displayData,
                  //       );
                  //     },
                  //   ),
                  // ),
                  const SizedBox(width: 14),
                  ModernBtn(
                    text: "Close",
                    textColor: Colors.black,

                    bgColor: Colors.yellowAccent,
                    width: 100,
                    height: 40,
                    onTap: _closeDialog,
                  ),
                  // Expanded(
                  //   child: _buildButton(
                  //     label: "Close",
                  //     backgroundColor: AccountDetailsColors.yellowButton,
                  //     textColor: AccountDetailsColors.textDark,
                  //     onPressed: ,
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared static builders (UI unchanged) ─────────────────────
  static Widget _buildDetailRow({
    required String label,
    required String value,
    Color valueColor = AccountDetailsColors.textWhite,
    bool isHighlight = false,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlight
                ? AccountDetailsColors.textWhite
                : AccountDetailsColors.textSecondary,
            fontSize: 14,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  static Widget _buildButton({
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        splashColor: textColor.withOpacity(0.2),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HELPER — show dialog
// ─────────────────────────────────────────────────────────────
/// Call this to show the account details dialog.
/// Pass only the data you already have:
/// { "userId": "...", "walletBalance": "..." }
/// The widget itself fetches today's report internally.
void showAccountDetailsDialog(
  BuildContext context,
  Map<String, dynamic> data, {
  VoidCallback? onClose,
}) {
  showDialog(
    context: context,
    barrierColor: AccountDetailsColors.overlayBlack.withOpacity(0.55),
    barrierDismissible: true,
    builder: (_) => AccountDetailsDialog(data: data, onClose: onClose),
  );
}
