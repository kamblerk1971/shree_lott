import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:shreelott/controller/home_controller.dart';
import 'package:shreelott/screens/helpers/batting_grid_view.dart';
import '../consts/app_colors.dart';
import '../models/shop_report_model.dart';
import '../service/ticket_print_service.dart';

class ShopReportDialog extends StatefulWidget {
  const ShopReportDialog({super.key});

  @override
  State<ShopReportDialog> createState() => _ShopReportDialogState();
}

class _ShopReportDialogState extends State<ShopReportDialog> {
  final HomeController controller = Get.put(HomeController());
  final Box appBox = Hive.box('app');

  final DateTime now = DateTime.now();

  late DateTime to = DateTime(now.year, now.month, now.day);
  late DateTime from = DateTime(now.year, now.month, now.day - 1);

  bool loading = false;
  ShopReportResponse? report;

  String _fmt(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── API ────────────────────────────────────────────────────
  Future<void> _load() async {
    if (from.isAfter(to)) {
      Get.snackbar('Error', 'Start date cannot be after End date');
      return;
    }

    setState(() => loading = true);

    try {
      final res = await controller.fetchReport(from: _fmt(from), to: _fmt(to));

      if (!mounted) return;

      setState(() {
        report = res;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      Get.snackbar('Error', 'Failed to load report');
    }
  }

  // ── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 650),
          child: Container(
            padding: const EdgeInsets.all(20),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(),
                const SizedBox(height: 8),
                _filters(),
                const SizedBox(height: 8),
                Flexible(child: _content()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────
  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Shop Report",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
      ],
    );
  }

  // ── Filters ────────────────────────────────────────────────
  Widget _filters() {
    final hasData = report != null && report!.reportData.rows.isNotEmpty;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: _dateField("Start Date", from, (d) {
              setState(() => from = d);
            }),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: _dateField("End Date", to, (d) {
              setState(() => to = d);
            }),
          ),
          const SizedBox(width: 12),
          ModernBtn(
            text: "Apply",
            bgColor: Colors.green,
            width: 100,
            height: 40,
            onTap: () {
              loading ? null : _load();
            },
          ),
          const SizedBox(width: 12),
          ModernBtn(
            text: "Print",
            textColor: Colors.black,
            bgColor: Colors.yellow,
            width: 100,
            height: 40,
            onTap: () {
              !hasData ? null : _printReport();
            },
          ),
        ],
      ),
    );
  }

  // ── Print ──────────────────────────────────────────────────
  // ✅ Uses pre-computed total from model (includes data_temp sale & commission)
  // ❌ Does NOT re-sum rows (rows don't include data_temp values)
  void _printReport() {
    final data = report!.reportData;
    final total = data.total;

    final String loginId = appBox.get('user_id', defaultValue: '');
    final String userName = appBox.get('username', defaultValue: '');
    final String name = appBox.get('owner_name', defaultValue: '');

    TicketPrintService.printPointSummaryReport(
      context: context,
      startDate: _fmt(from),
      endDate: _fmt(to),
      rptDateTime: DateFormat('dd-MM-yyyy hh:mm:ss a').format(DateTime.now()),
      loginId: loginId.toString(),
      userName: userName,
      name: name,
      totalSale: total.totalLoad,
      totalCommission: total.commission,
      totalWinning: total.winning,
      totalNet: total.endPoint,
      rows: data.rows,
    );
  }

  // ── Date Field ─────────────────────────────────────────────
  Widget _dateField(
    String label,
    DateTime value,
    ValueChanged<DateTime> onChanged,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.primaryMedium,
                  onPrimary: AppColors.textPrimary,
                  surface: AppColors.primaryDarker,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.borderLight.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: AppColors.borderLight.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: AppColors.accentGold, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          filled: true,
          fillColor: AppColors.primaryDarker.withOpacity(0.3),
        ),
        child: Text(
          "${value.day}/${value.month}/${value.year}",
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
      ),
    );
  }

  // ── Content ────────────────────────────────────────────────
  Widget _content() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold),
        ),
      );
    }

    if (report == null || report!.reportData.rows.isEmpty) {
      return const Center(
        child: Text(
          "No data available",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      );
    }

    return SingleChildScrollView(child: _table(report!.reportData));
  }

  // ── Table ──────────────────────────────────────────────────
  Widget _table(ShopReportData data) {
    return Column(
      children: [
        _row(true, ["Sr No", "Date", "Sale", "Comm.", "Win", "End"]),
        const SizedBox(height: 6),
        for (int i = 0; i < data.rows.length; i++)
          _row(false, [
            "${i + 1}",
            data.rows[i].date,
            data.rows[i].totalLoad.toStringAsFixed(0),
            data.rows[i].commission.toStringAsFixed(2),
            data.rows[i].winning.toStringAsFixed(0),
            data.rows[i].endPoint.toStringAsFixed(2),
          ]),
        const SizedBox(height: 10),
        // ✅ Total row uses data.total which includes data_temp values
        _row(true, [
          "Total",
          "",
          data.total.totalLoad.toStringAsFixed(0),
          data.total.commission.toStringAsFixed(2),
          data.total.winning.toStringAsFixed(0),
          data.total.endPoint.toStringAsFixed(2),
        ]),
      ],
    );
  }

  Widget _row(bool header, List<String> cells) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: header
            ? AppColors.borderLight.withOpacity(0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(header ? 6 : 0),
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderLight.withOpacity(0.15),
            width: 0.6,
          ),
        ),
      ),
      child: Row(
        children: cells.map((e) {
          return Expanded(
            child: Text(
              e,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: header ? FontWeight.w600 : FontWeight.normal,
                color: header ? AppColors.accentGold : AppColors.textPrimary,
                letterSpacing: header ? 0.3 : 0.2,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HELPER — show dialog
// ─────────────────────────────────────────────────────────────
void showShopReportDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.55),
    barrierDismissible: true,
    builder: (_) => const ShopReportDialog(),
  );
}
