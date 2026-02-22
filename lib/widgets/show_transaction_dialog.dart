import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shreelott/controller/wallet_controller.dart';
import 'package:shreelott/screens/helpers/batting_grid_view.dart';
import '../consts/app_colors.dart';
import '../controller/home_controller.dart';

Future<void> openTransactionDialog(
  BuildContext context,
  String userId,
  String drawTime,
) async {
  final controller = HomeController();
  print(drawTime);

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.transparent,
    builder: (_) {
      return Dialog(
        insetPadding: EdgeInsets.zero,
        elevation: 0,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        child: _TransactionDialog(
          controller: controller,
          userId: userId,
          drawTime: drawTime,
        ),
      );
    },
  ).then((_) => controller.dispose());
}

class _TransactionDialog extends StatefulWidget {
  final HomeController controller;
  final String userId;
  final String drawTime;

  const _TransactionDialog({
    required this.controller,
    required this.userId,
    required this.drawTime,
  });

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  late Future<List<TransactionModel>> _future;

  @override
  void initState() {
    super.initState();
    _future =
        widget.controller.getTransactions() as Future<List<TransactionModel>>;
  }

  void _reload() {
    setState(() {
      _future =
          widget.controller.getTransactions() as Future<List<TransactionModel>>;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 500,
                minWidth: 300,
                maxHeight: 600,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: RadialGradient(
                    center: const Alignment(0.3, -0.3),
                    radius: 1.2,
                    colors: [
                      AppColors.primaryMedium.withOpacity(0.95),
                      AppColors.primaryDarker,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                  boxShadow: AppColors.premiumCardShadow,
                  border: Border.all(
                    color: AppColors.borderLight.withOpacity(0.15),
                    width: 1.5,
                  ),
                ),
                child: FutureBuilder<List<TransactionModel>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _loading();
                    }
                    if (snapshot.hasError ||
                        snapshot.data == null ||
                        snapshot.data!.isEmpty) {
                      return _empty(context);
                    }
                    return _content(context, snapshot.data!, widget.userId);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onCancel(TransactionModel t) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return _CancelBetDialog(
          controller: widget.controller,
          transaction: t,
          onSuccess: () {
            Navigator.pop(context);
            _reload();
          },
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    List<TransactionModel> list,
    String userId,
  ) {
    return Stack(
      children: [
        Column(
          children: [
            _header(),
            const SizedBox(height: 8),
            _tableHeader(),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: list.length,
                itemBuilder: (_, i) => _tableRow(
                  i + 1,
                  list[i],
                  _onCancel,
                  context,
                  userId,
                  widget.drawTime,
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: 10,
          right: 10,
          child: Material(
            color: Colors.transparent,
            child: ModernBtn(
              text: "Close",
              textColor: Colors.black,
              bgColor: Colors.yellow,
              width: 100,
              height: 30,
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 48, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          Text(
            "Your Transactions",
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            "Last 15 transactions",
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _CancelBetDialog extends StatefulWidget {
  final HomeController controller;
  final TransactionModel transaction;
  final VoidCallback onSuccess;

  const _CancelBetDialog({
    required this.controller,
    required this.transaction,
    required this.onSuccess,
  });

  @override
  State<_CancelBetDialog> createState() => _CancelBetDialogState();
}

class _CancelBetDialogState extends State<_CancelBetDialog> {
  bool _loading = false;
  bool? _success;
  String message = "";

  Future<void> _cancel() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      final result = await widget.controller.cancelBet(
        id: widget.transaction.pid.replaceAll("SL", ""),
      );

      debugPrint("Cancel Response: $result");

      final WalletController walletController = Get.put(WalletController());

      final bool isSuccess = result != null && result["success"] == true;

      final String responseMessage =
          result?["message"]?.toString() ?? "Unknown error";

      if (result != null && result["wallet"] != null) {
        debugPrint("Updating the wallet balance");
        walletController.setBalance((result["wallet"] as num).toDouble());
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
        _success = isSuccess;
        message = responseMessage;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? ""),
          backgroundColor: isSuccess
              ? AppColors.accentGreen
              : const Color(0xFFFF385C),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      if (isSuccess) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) {
            widget.onSuccess();
          }
        });
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint("Cancel Error: $e");

      setState(() {
        _loading = false;
        _success = false;
        message = "Something went wrong";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong"),
          backgroundColor: Color(0xFFFF385C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: RadialGradient(
            center: const Alignment(0.3, -0.3),
            radius: 1.2,
            colors: [
              AppColors.primaryMedium.withOpacity(0.95),
              AppColors.primaryDarker,
            ],
            stops: const [0.0, 1.0],
          ),
          boxShadow: AppColors.premiumCardShadow,
          border: Border.all(
            color: AppColors.borderLight.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _success == true
                      ? AppColors.accentGold.withOpacity(0.1)
                      : const Color(0xFFFF385C).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _success == true ? Icons.check : Icons.warning_amber_rounded,
                  size: 20,
                  color: _success == true
                      ? AppColors.accentGold
                      : const Color(0xFFFF385C),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _success == true
                    ? "Bet cancelled"
                    : _success == false
                    ? message ?? "Cancellation failed"
                    : "Cancel this bet?",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _success == true
                    ? "Your bet has been cancelled successfully."
                    : _success == false
                    ? "Unable to cancel. Please try again."
                    : "Once cancelled, this bet won't be included in the draw.",
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accentGold,
                    ),
                  ),
                )
              else if (_success == null)
                Column(
                  children: [
                    ModernBtn(
                      text: "Keep",
                      bgColor: Colors.white,
                      textColor: Colors.black,
                      width: 300,
                      height: 40,
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: OutlinedButton(
                    //     style: OutlinedButton.styleFrom(
                    //       foregroundColor: AppColors.textPrimary,
                    //       side: BorderSide(
                    //         color: AppColors.borderLight.withOpacity(0.3),
                    //       ),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(8),
                    //       ),
                    //     ),
                    //     onPressed: () => Navigator.pop(context),
                    //     child: const Text("Keep"),
                    //   ),
                    // ),
                    const SizedBox(height: 8),
                    ModernBtn(
                      text: "Cancel Bet",
                      bgColor: Colors.red,
                      width: 300,
                      height: 40,
                      onTap: _cancel,
                    ),
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: ElevatedButton(
                    //     style: ElevatedButton.styleFrom(
                    //       backgroundColor: const Color(0xFFE53935),
                    //       foregroundColor: AppColors.textPrimary,
                    //       elevation: 8,
                    //       shadowColor: const Color(0xFFE53935).withOpacity(
                    //           0.5),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(8),
                    //       ),
                    //     ),
                    //     onPressed: _cancel,
                    //     child: const Text("Cancel Bet"),
                    //   ),
                    // ),
                  ],
                )
              else
                ModernBtn(
                  text: "Close",
                  bgColor: Colors.white,
                  textColor: Colors.black,
                  width: 300,
                  height: 40,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton(
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: AppColors.borderLight.withOpacity(0.2),
              //       foregroundColor: AppColors.textPrimary,
              //       elevation: 0,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(8),
              //         side: BorderSide(
              //           color: AppColors.borderLight.withOpacity(0.3),
              //         ),
              //       ),
              //     ),
              //     onPressed: () => Navigator.pop(context),
              //     child: const Text(
              //       "Close",
              //       style: TextStyle(
              //         color: AppColors.textPrimary,
              //         fontWeight: FontWeight.w500,
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _tableHeader() {
  const style = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
    child: Row(
      children: const [
        Expanded(flex: 2, child: Text("Sr No", style: style)),
        Expanded(flex: 4, child: Text("Ticket", style: style)),
        Expanded(flex: 2, child: Text("Slot", style: style)),
        Expanded(
          flex: 2,
          child: Text("Load", style: style, textAlign: TextAlign.right),
        ),
        Expanded(
          flex: 3,
          child: Text("Action", style: style, textAlign: TextAlign.center),
        ),
      ],
    ),
  );
}

Widget _tableRow(
  int index,
  TransactionModel t,
  Function(TransactionModel) onCancel,
  BuildContext context,
  String userId,
  String drawTime,
) {
  final bool isActive = t.status.toLowerCase() == "active";

  /// ===== CLEAN & NORMALIZE TIME =====
  String normalizeTime(String value, {bool minus15 = false}) {
    try {
      value = value.trim().toLowerCase();

      bool isPM = value.contains("pm");
      bool isAM = value.contains("am");

      value = value.replaceAll("am", "").replaceAll("pm", "").trim();

      final parts = value.split(":");
      int hour = int.parse(parts[0]);
      int minute = parts.length > 1 ? int.parse(parts[1]) : 0;

      // Convert to 24-hour
      if (isPM && hour != 12) {
        hour += 12;
      }
      if (isAM && hour == 12) {
        hour = 0;
      }

      DateTime time = DateTime(2000, 1, 1, hour, minute);

      if (minus15) {
        time = time.subtract(const Duration(minutes: 15));
      }

      final String hourStr = time.hour.toString().padLeft(2, '0');
      final String minStr = time.minute.toString().padLeft(2, '0');

      return "$hourStr:$minStr";
    } catch (_) {
      return value;
    }
  }

  final String cleanDrawTime = normalizeTime(drawTime);
  final String cleanSlotTime = normalizeTime(t.slot, minus15: true);

  final bool showCancelButton = cleanDrawTime == cleanSlotTime;

  print("cleanDrawTime :$cleanDrawTime");
  print("cleanSlotTime :$cleanSlotTime");

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            index.toString(),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            t.pid,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.accentGold,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            "${(int.parse(t.slot.split(':')[0]) % 12 == 0 ? 12 : int.parse(t.slot.split(':')[0]) % 12)}:${t.slot.split(':')[1]} ${int.parse(t.slot.split(':')[0]) >= 12 ? 'PM' : 'AM'}",
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            "₹ ${t.totalLoad}",
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: isActive
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// ===== CANCEL BUTTON (ONLY IF TIME MATCHES) =====
                    if (showCancelButton)
                      ModernBtn(
                        text: "Cancel",
                        bgColor: Colors.red,
                        width: 100,
                        height: 30,
                        onTap: () {
                          onCancel(t);
                        },
                      ),

                    // SizedBox(
                    //   width: double.infinity,
                    //   height: 26,
                    //   child: OutlinedButton(
                    //     onPressed: () => onCancel(t),
                    //     style: ButtonStyle(
                    //       foregroundColor: const MaterialStatePropertyAll(
                    //         Color(0xFFFF6B6B),
                    //       ),
                    //       side: const MaterialStatePropertyAll(
                    //         BorderSide(color: Color(0xFFFF6B6B), width: 1),
                    //       ),
                    //       overlayColor: MaterialStateProperty.resolveWith((
                    //         states,
                    //       ) {
                    //         if (states.contains(MaterialState.pressed)) {
                    //           return const Color(0xFFFF6B6B).withOpacity(0.15);
                    //         }
                    //         return null;
                    //       }),
                    //       backgroundColor: MaterialStateProperty.resolveWith((
                    //         states,
                    //       ) {
                    //         if (states.contains(MaterialState.pressed)) {
                    //           return const Color(0xFFFF6B6B).withOpacity(0.08);
                    //         }
                    //         return Colors.transparent;
                    //       }),
                    //       padding: const MaterialStatePropertyAll(
                    //         EdgeInsets.zero,
                    //       ),
                    //       shape: MaterialStatePropertyAll(
                    //         RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.circular(4),
                    //         ),
                    //       ),
                    //     ),
                    //     child: const Text(
                    //       "Cancel",
                    //       style: TextStyle(
                    //         fontSize: 12,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    if (showCancelButton) const SizedBox(height: 6),

                    /// ===== REPRINT BUTTON =====
                    ModernBtn(
                      text: "Reprint",
                      textColor: Colors.black,
                      bgColor: Colors.yellow,
                      width: 100,
                      height: 30,
                      onTap: () {
                        HomeController controller = HomeController();
                        controller.reprintTicket(
                          ticketId: t.pid.replaceAll("SL", ""),
                          context: context,
                          userId: userId,
                        );
                      },
                    ),
                    // SizedBox(
                    //   width: double.infinity,
                    //   height: 26,
                    //   child: OutlinedButton(
                    //     onPressed: () {
                    //
                    //     },
                    //     style: ButtonStyle(
                    //       foregroundColor: MaterialStatePropertyAll(
                    //         AppColors.accentGold,
                    //       ),
                    //       side: MaterialStatePropertyAll(
                    //         BorderSide(color: AppColors.accentGold, width: 1),
                    //       ),
                    //       overlayColor: MaterialStateProperty.resolveWith((states,) {
                    //         if (states.contains(MaterialState.pressed)) {
                    //           return AppColors.accentGold.withOpacity(0.15);
                    //         }
                    //         return null;
                    //       }),
                    //       backgroundColor: MaterialStateProperty.resolveWith((
                    //           states,) {
                    //         if (states.contains(MaterialState.pressed)) {
                    //           return AppColors.accentGold.withOpacity(0.08);
                    //         }
                    //         return Colors.transparent;
                    //       }),
                    //       padding: const MaterialStatePropertyAll(
                    //         EdgeInsets.zero,
                    //       ),
                    //       shape: MaterialStatePropertyAll(
                    //         RoundedRectangleBorder(
                    //           borderRadius: BorderRadius.circular(4),
                    //         ),
                    //       ),
                    //     ),
                    //     child: const Text(
                    //       "Reprint",
                    //       style: TextStyle(
                    //         fontSize: 12,
                    //         fontWeight: FontWeight.w600,
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                )
              : const Text(
                  "Cancelled",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
        ),
      ],
    ),
  );
}

Widget _loading() {
  return const SizedBox(
    height: 220,
    child: Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold),
      ),
    ),
  );
}

Widget _empty(BuildContext context) {
  return SizedBox(
    height: 260,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.grey.shade800, Colors.grey.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.receipt_long_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),

        const SizedBox(height: 18),

        // Title
        Text(
          "No Transactions Found",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 6),

        // Subtitle
        Text(
          "Looks like you haven't made\nany transactions yet.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 24),

        // Airbnb Style Close Button
        GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF385C), // Airbnb pink
                  Color(0xFFE31C5F),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF385C).withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Text(
              "Go Back",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
