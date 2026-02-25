import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shreelott/consts/api_consts.dart' hide ApiConstants;
import 'package:shreelott/widgets/show_info_dialog.dart';
import 'package:shreelott/widgets/show_transaction_dialog.dart';

import '../../controller/home_controller.dart';

// ===================== MODEL =====================
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../controller/index_controller.dart';
import '../../controller/refresh_controller.dart';
import '../../controller/wallet_controller.dart';
import '../../models/range_data.dart';
import '../../service/ticket_print_service.dart';
import '../../widgets/show_advanced_draw_dialog.dart';
import '../../widgets/show_result_dialog.dart';

import 'package:flutter/material.dart';

class BettingGridModel {
  TextEditingController barcodeController = TextEditingController();
  final TextEditingController barcodeCtrl = TextEditingController();
  final FocusNode barcodeFocus = FocusNode();

  Timer? _debounce;
  bool _isProcessing = false;
  final IndexController indexController = Get.put(IndexController());

  static const double cellW = 78;
  static const double cellH = 32;
  static const double headerH = 34;

  bool even = false;
  bool odd = false;
  bool high = false;
  bool low = true;
  bool block = false;
  bool isFPChecked = false;

  int seriesStart = 0;
  int visibleStart = 0;
  int visibleEnd = 99;

  int selectedSeries = 0;
  int selectedRange = 0;

  Set<int> selectedSeries_Set = {0};
  Set<int> selectedRange_Set = {0};

  final Map<String, TextEditingController> ctrls = {};
  final Map<int, TextEditingController> headerCtrls = {};
  final Map<int, TextEditingController> rowCtrls = {};

  // ─── Unified tracking for both modes ───────────────────────────────────────
  // LOW mode totals (based on selectedPoint)
  int lowQty = 0;
  double lowAmount = 0.0;

  // HIGH mode totals (based on fixed 2.0 * multiplier per range)
  int highQty = 0;
  double highAmount = 0.0;

  // Convenience getters that return the active mode's values
  int get qty => high ? highQty : lowQty;

  double get amount => high ? highAmount : lowAmount;

  // ───────────────────────────────────────────────────────────────────────────

  late List<RangeData> ranges;
  final List<double> pointOptions = [2, 4, 10, 20, 40];
  double selectedPoint = 2;
  int limitValue = 0;
  Set<int> selectedPtSet = {};

  BettingGridModel() {
    ranges = [
      RangeData('0000-0099', const Color(0xFFFF385C), 0),
      RangeData('0100-0199', const Color(0xFF717171), 0),
      RangeData('0200-0299', const Color(0xFF0077B6), 0),
      RangeData('0300-0399', const Color(0xFF00A699), 2),
      RangeData('0400-0499', const Color(0xFFD70466), 4),
      RangeData('0500-0599', const Color(0xFF9333EA), 10),
      RangeData('0600-0699', const Color(0xFFF77F00), 20),
      RangeData('0700-0799', const Color(0xFF7CB342), 40),
      RangeData('0800-0899', const Color(0xFF5E35B1), 0),
      RangeData('0900-0999', const Color(0xFF00ACC1), 0),
    ];
    selectedPoint = ranges[3].points;
  }

  final List<Color> colors = [
    const Color(0xFFFF385C),
    const Color(0xFF717171),
    const Color(0xFF0077B6),
    const Color(0xFF00A699),
    const Color(0xFFD70466),
    const Color(0xFF9333EA),
    const Color(0xFFF77F00),
    const Color(0xFF7CB342),
    const Color(0xFF5E35B1),
    const Color(0xFF00ACC1),
  ];

  /// Range multipliers used in HIGH mode.
  static const List<int> _rangeMultipliers = [1, 1, 2, 3, 5, 5, 10, 20, 25, 25];

  // ─── Focus / Navigation ────────────────────────────────────────────────────

  /// Switches the view to a specific series and resets the visible range.
  void focusSeries(int series) {
    // 1. Update the active series index
    selectedSeries = series;

    // 2. Calculate the global starting point (e.g., Series 2 starts at 2000)
    seriesStart = series * 1000;

    // 3. Update the visible window based on the currently selected range index (0-9)
    visibleStart = seriesStart + (selectedRange * 100);
    visibleEnd = visibleStart + 99;

    // 4. Reset temporary UI controllers
    headerCtrls.clear();
    rowCtrls.clear();

    // 5. Trigger a recalculation of totals for the new view
    recalc();
  }

  // ─── Row apply ─────────────────────────────────────────────────────────────

  void applyRowValue(int row, String v, BuildContext context) {
    final wallet = Get.find<WalletController>();

    final bool isEmpty = v.trim().isEmpty;
    final int newQty = int.tryParse(v) ?? 0;

    if (!isEmpty && newQty <= 0) return;

    if (selectedPoint == 0.0 && !high) {
      showSelectPointSnackBar(context);
      return;
    }

    double totalRequired = 0.0;
    double totalRefund = 0.0;

    final Set<int> targets = {};

    // ─── STEP 1: BUILD TARGETS ─────────────────────────────────────────────
    for (final s in selectedSeries_Set) {
      if (high) {
        // HIGH → all 10 ranges
        for (int r = 0; r < 10; r++) {
          final base = s * 1000 + r * 100 + row * 10;
          for (int c = 0; c < 10; c++) {
            final n = base + c;
            if (!_allow(n)) continue;
            if (odd && n.isEven) continue;
            if (even && n.isOdd) continue;
            targets.add(n);
          }
        }
      } else {
        // LOW → selected ranges only
        for (final r in selectedRange_Set) {
          final base = s * 1000 + r * 100 + row * 10;
          for (int c = 0; c < 10; c++) {
            final n = base + c;
            if (!_allow(n)) continue;
            if (odd && n.isEven) continue;
            if (even && n.isOdd) continue;
            targets.add(n);
          }
        }
      }
    }

    if (targets.isEmpty) return;

    // ─── STEP 2: WALLET CALCULATION ────────────────────────────────────────
    for (final n in targets) {
      final int oldQty = cellQty[n] ?? 0;
      final int finalQty = isEmpty ? 0 : newQty;
      final int diffQty = finalQty - oldQty;

      final double costPerCell = _costPerCell(n);

      if (diffQty > 0) {
        totalRequired += diffQty * costPerCell;
      } else if (diffQty < 0) {
        totalRefund += diffQty.abs() * costPerCell;
      }
    }

    // ─── STEP 3: WALLET CHECK ──────────────────────────────────────────────
    if (totalRequired > 0 && !wallet.hasEnough(totalRequired)) {
      debugPrint("❌ Low balance. Needed: $totalRequired");
      showLowBalanceSnackBar(context);
      return;
    }

    // ─── STEP 4: APPLY WALLET ─────────────────────────────────────────────
    if (totalRequired > 0) wallet.deduct(totalRequired);
    if (totalRefund > 0) wallet.add(totalRefund);

    // ─── STEP 5: APPLY VALUES ─────────────────────────────────────────────
    for (final n in targets) {
      final int finalQty = isEmpty ? 0 : newQty;
      cellQty[n] = finalQty;

      final s = n ~/ 1000;
      final r = (n % 1000) ~/ 100;

      final ctrl = _getCtrl(s, r, n);
      ctrl.text = finalQty == 0 ? "" : finalQty.toString();
    }

    recalc();

    debugPrint(
      "ROW DONE | Mode=${high ? 'HIGH' : 'LOW'} | "
      "Deduct=$totalRequired Refund=$totalRefund "
      "Wallet=${wallet.walletBalance.value}",
    );
  }

  // ─── Column apply ──────────────────────────────────────────────────────────

  void applyColumnValue(int col, String v, BuildContext context) {
    final wallet = Get.find<WalletController>();

    final bool isEmpty = v.trim().isEmpty;
    final int newQty = int.tryParse(v) ?? 0;

    if (!isEmpty && newQty <= 0) return;

    if (selectedPoint == 0.0 && !high) {
      showSelectPointSnackBar(context);
      return;
    }

    double totalRequired = 0.0;
    double totalRefund = 0.0;

    final Set<int> targets = {};

    // ─── STEP 1: BUILD TARGETS ─────────────────────────────────────────────
    for (final s in selectedSeries_Set) {
      if (high) {
        // HIGH → all 10 ranges
        for (int r = 0; r < 10; r++) {
          final base = s * 1000 + r * 100 + col;
          for (int row = 0; row < 10; row++) {
            final n = base + row * 10;
            if (!_allow(n)) continue;
            if (odd && n.isEven) continue;
            if (even && n.isOdd) continue;
            targets.add(n);
          }
        }
      } else {
        // LOW → selected ranges only
        for (final r in selectedRange_Set) {
          final base = s * 1000 + r * 100 + col;
          for (int row = 0; row < 10; row++) {
            final n = base + row * 10;
            if (!_allow(n)) continue;
            if (odd && n.isEven) continue;
            if (even && n.isOdd) continue;
            targets.add(n);
          }
        }
      }
    }

    if (targets.isEmpty) return;

    // ─── STEP 2: WALLET CALCULATION ────────────────────────────────────────
    for (final n in targets) {
      final int oldQty = cellQty[n] ?? 0;
      final int finalQty = isEmpty ? 0 : newQty;
      final int diffQty = finalQty - oldQty;

      final double costPerCell = _costPerCell(n);

      if (diffQty > 0) {
        totalRequired += diffQty * costPerCell;
      } else if (diffQty < 0) {
        totalRefund += diffQty.abs() * costPerCell;
      }
    }

    // ─── STEP 3: WALLET CHECK ──────────────────────────────────────────────
    if (totalRequired > 0 && !wallet.hasEnough(totalRequired)) {
      debugPrint("❌ Low balance. Needed: $totalRequired");
      showLowBalanceSnackBar(context);
      return;
    }

    // ─── STEP 4: APPLY WALLET ─────────────────────────────────────────────
    if (totalRequired > 0) wallet.deduct(totalRequired);
    if (totalRefund > 0) wallet.add(totalRefund);

    // ─── STEP 5: APPLY VALUES SAFELY ──────────────────────────────────────
    for (final n in targets) {
      final int finalQty = isEmpty ? 0 : newQty;
      cellQty[n] = finalQty;

      final s = n ~/ 1000;
      final r = (n % 1000) ~/ 100;

      final ctrl = _getCtrl(s, r, n);
      final String newText = finalQty == 0 ? "" : finalQty.toString();

      if (ctrl.text != newText) {
        ctrl.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    }

    recalc();

    debugPrint(
      "COLUMN DONE | Mode=${high ? 'HIGH' : 'LOW'} | "
      "Deduct=$totalRequired Refund=$totalRefund "
      "Wallet=${wallet.walletBalance.value}",
    );
  }

  // ─── FP Generation ─────────────────────────────────────────────────────────

  Set<int> _generateFP(int fullNumber) {
    final int series = fullNumber ~/ 100; // first 2 digits
    final int lastTwo = fullNumber % 100; // last 2 digits

    final int d1 = lastTwo ~/ 10;
    final int d2 = lastTwo % 10;

    final int p1 = (d1 + 5) % 10;
    final int p2 = (d2 + 5) % 10;

    final Set<int> result = {};

    final List<int> firstOptions = [d1, p1];
    final List<int> secondOptions = [d2, p2];

    for (final a in firstOptions) {
      for (final b in secondOptions) {
        result.add(series * 100 + a * 10 + b);
        result.add(series * 100 + b * 10 + a);
      }
    }

    return result;
  }

  // ─── Cell changed ──────────────────────────────────────────────────────────

  final walletController = Get.find<WalletController>();
  final Map<int, int> cellQty = {};

  void onCellChanged(int n, String v, BuildContext context, bool isFPChecked) {
    debugPrint("\n========== onCellChanged START ==========");

    final int newQty = int.tryParse(v) ?? 0;

    if (selectedPoint == 0.0) {
      showSelectPointSnackBar(context);
      return;
    }

    final wallet = Get.find<WalletController>();
    debugPrint("Wallet Before : ${wallet.walletBalance.value}");

    final Set<int> rawTargets = {};

    // ─── STEP 1: BUILD TARGETS ─────────────────────────────────────────────
    for (final s in selectedSeries_Set) {
      if (isFPChecked) {
        // ── FP LOGIC ──────────────────────────────────────────────────────
        final Set<int> fpNumbers = _generateFP(n);

        for (final fp in fpNumbers) {
          final int lastTwo = fp % 100;

          if (high) {
            // FP + HIGH → all 10 ranges
            for (int r = 0; r < 10; r++) {
              final int candidate = s * 1000 + r * 100 + lastTwo;
              if (!_allow(candidate)) continue;
              rawTargets.add(candidate);
            }
          } else {
            // FP + LOW → selected ranges only
            for (final r in selectedRange_Set) {
              final int candidate = s * 1000 + r * 100 + lastTwo;
              if (!_allow(candidate)) continue;
              rawTargets.add(candidate);
            }
          }
        }
      } else {
        // ── NORMAL HIGH / LOW ─────────────────────────────────────────────
        final int lastTwoDigits = n % 100;

        if (high) {
          // HIGH → all 10 ranges
          for (int r = 0; r < 10; r++) {
            final int candidate = s * 1000 + r * 100 + lastTwoDigits;
            if (!_allow(candidate)) continue;
            rawTargets.add(candidate);
          }
        } else {
          // LOW → original logic
          for (final r in selectedRange_Set) {
            final int baseStart = s * 1000 + r * 100;

            for (int i = 0; i < 100; i++) {
              final int candidate = baseStart + i;

              if (!odd && !even) {
                if (candidate % 100 != lastTwoDigits) continue;
              }

              if (even && !odd && candidate.isOdd) continue;
              if (odd && !even && candidate.isEven) continue;

              if (!_allow(candidate)) continue;

              rawTargets.add(candidate);
            }
          }
        }
      }
    }

    if (rawTargets.isEmpty) return;

    double totalRequired = 0.0;
    double totalRefund = 0.0;

    // ─── STEP 2: CALCULATE WALLET DIFFERENCE ──────────────────────────────
    for (final target in rawTargets) {
      final int oldQty = cellQty[target] ?? 0;
      final int diffQty = newQty - oldQty;

      final double costPerCell = _costPerCell(target);

      if (diffQty > 0) {
        totalRequired += diffQty * costPerCell;
      } else if (diffQty < 0) {
        totalRefund += diffQty.abs() * costPerCell;
      }
    }

    // ─── STEP 3: WALLET CHECK ──────────────────────────────────────────────
    if (totalRequired > 0 && !wallet.hasEnough(totalRequired)) {
      debugPrint("❌ Low balance. Needed: $totalRequired");
      showLowBalanceSnackBar(context);
      return;
    }

    // ─── STEP 4: APPLY WALLET ─────────────────────────────────────────────
    if (totalRequired > 0) wallet.deduct(totalRequired);
    if (totalRefund > 0) wallet.add(totalRefund);

    // ─── STEP 5: APPLY VALUES TO UI ───────────────────────────────────────
    for (final target in rawTargets) {
      cellQty[target] = newQty;

      final s = target ~/ 1000;
      final r = (target % 1000) ~/ 100;

      final ctrl = _getCtrl(s, r, target);
      final String newText = newQty == 0 ? "" : newQty.toString();

      if (ctrl.text != newText) {
        ctrl.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    }

    recalc();

    debugPrint("Total Deducted : $totalRequired");
    debugPrint("Wallet After   : ${wallet.walletBalance.value}");
    debugPrint("========== onCellChanged END ==========\n");
  }

  // ─── Page / Toggle ─────────────────────────────────────────────────────────

  void pageRange(bool up) {
    if (up) {
      if (selectedRange < ranges.length - 1) selectedRange++;
    } else {
      if (selectedRange > 0) selectedRange--;
    }
    selectedRange_Set
      ..clear()
      ..add(selectedRange);
    _updateVisible();
  }

  void toggleSeriesSelection(int s) {
    if (selectedSeries_Set.contains(s)) {
      if (selectedSeries_Set.length > 1) selectedSeries_Set.remove(s);
    } else {
      selectedSeries_Set.add(s);
    }
    selectedSeries = selectedSeries_Set.last;
    seriesStart = selectedSeries * 1000;
    _updateVisible();
  }

  void toggleAllSeries() {
    if (selectedSeries_Set.length == 10) {
      // Deselect all → reset to default series 0
      selectedSeries_Set
        ..clear()
        ..add(0);
      selectedSeries = 0;
    } else {
      // Select all → 0 to 9
      selectedSeries_Set
        ..clear()
        ..addAll(List.generate(10, (i) => i));
      selectedSeries = 0; // keep active as first, matching JS behavior
    }
    _updateVisible();
  }

  void toggleRangeSelection(int r) {
    if (selectedRange_Set.contains(r)) {
      if (selectedRange_Set.length > 1) selectedRange_Set.remove(r);
    } else {
      selectedRange_Set.add(r);
    }
    selectedRange = selectedRange_Set.last;
    selectedPoint = ranges[selectedRange].points;
    _updateVisible();
  }

  void _updateVisible() {
    visibleStart = seriesStart + (selectedRange * 100);
    visibleEnd = visibleStart + 99;
    headerCtrls.clear();
    rowCtrls.clear();
    recalc();
  }

  // ─── Utilities ─────────────────────────────────────────────────────────────

  String _key(int s, int r, int n) => 'S${s}_R${r}_N$n';

  TextEditingController _getCtrl(int s, int r, int n) {
    return ctrls.putIfAbsent(_key(s, r, n), () => TextEditingController());
  }

  bool _allow(int n) =>
      (!even && !odd) || (even && n.isEven) || (odd && n.isOdd);

  /// Returns the cost per single unit for number [n] based on the current mode.
  double _costPerCell(int n) {
    if (high) {
      final int rangeIndex = (n % 1000) ~/ 100;
      final int multiplier = _rangeMultipliers[rangeIndex];
      return 2.0 * multiplier;
    } else {
      return selectedPoint;
    }
  }

  void toggleEven() {
    even = !even;
    if (even) odd = false;
  }

  void toggleOdd() {
    odd = !odd;
    if (odd) even = false;
  }

  void toggleBlock() => block = !block;

  void highLow(bool isHigh) {
    for (int n = visibleStart; n <= visibleEnd; n++) {
      final local = n % 100;
      if (((isHigh && local >= 50) || (!isHigh && local < 50)) && _allow(n)) {
        _getCtrl(selectedSeries, selectedRange, n).text = '1';
      }
    }
    recalc();
  }

  // ─── Recalculation ─────────────────────────────────────────────────────────

  /// Recalculates both [lowQty]/[lowAmount] and [highQty]/[highAmount]
  /// by scanning ALL numbers across ALL series (0-9) and ALL ranges (0-9).
  ///
  /// • LOW totals  → based on [selectedPoint] per cell
  /// • HIGH totals → based on fixed 2.0 × range multiplier per cell
  void recalc() {
    lowQty = 0;
    lowAmount = 0.0;
    highQty = 0;
    highAmount = 0.0;

    for (int s = 0; s < 10; s++) {
      for (int r = 0; r < ranges.length; r++) {
        final int start = s * 1000 + r * 100;
        final int multiplier = _rangeMultipliers[r];

        for (int n = start; n <= start + 99; n++) {
          final int v = cellQty[n] ?? 0;
          if (v == 0) continue;

          // LOW accumulation
          lowQty += v;
          lowAmount += v * selectedPoint;

          // HIGH accumulation
          highQty += v;
          highAmount += v * 2.0 * multiplier;
        }
      }
    }
  }

  // ─── Data Retrieval ────────────────────────────────────────────────────────

  int getSeriesQuantity(int series) {
    int total = 0;
    for (int range = 0; range < ranges.length; range++) {
      final int start = series * 1000 + range * 100;
      for (int n = start; n <= start + 99; n++) {
        total += cellQty[n] ?? 0;
      }
    }
    return total;
  }

  double getSeriesAmount(int series) =>
      getSeriesQuantity(series) * selectedPoint;

  Map<int, int> collectAllNumbersForPrint() {
    final Map<int, int> result = {};
    for (int s = 0; s < 10; s++) {
      for (int r = 0; r < ranges.length; r++) {
        final int start = s * 1000 + r * 100;
        for (int n = start; n <= start + 99; n++) {
          final int v = cellQty[n] ?? 0;
          if (v > 0) result[n] = v;
        }
      }
    }
    return result;
  }

  int getTotalQuantityAllSelected() {
    int total = 0;
    for (final s in selectedSeries_Set) {
      for (int r = 0; r < ranges.length; r++) {
        final int start = s * 1000 + r * 100;
        for (int n = start; n <= start + 99; n++) {
          total += cellQty[n] ?? 0;
        }
      }
    }
    return total;
  }

  double getTotalAmountAllSelected() =>
      getTotalQuantityAllSelected() * selectedPoint;

  // ─── UI Feedback ───────────────────────────────────────────────────────────

  void showLowBalanceSnackBar(BuildContext context) {
    _showSnack(context, 'Low balance! Limit reached.');
  }

  void showSelectPointSnackBar(BuildContext context) {
    _showSnack(context, 'Select a Point Value.');
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: const Color(0xFF0071CE),
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              msg,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Clear ─────────────────────────────────────────────────────────────────

  Future<void> clear(List slots, {bool isRefreshing = false}) async {
    slots.clear();
    focusSeries(0);
    selectedRange = 0;
    debugPrint("========== CLEAR START ==========");

    // 1. Incoming state
    debugPrint("isRefreshing: $isRefreshing");
    debugPrint("Slots received: ${slots.length}");

    // 2. Calculate slot multiplier
    final int slotMultiplier = slots.isEmpty ? 1 : slots.length;
    debugPrint("Step 1 → Slot Multiplier: $slotMultiplier");

    // 3. Recalculate current totals before clear
    recalc();
    debugPrint(
      "Step 2 → Before Clear Totals:"
      " LOW Qty=$lowQty Amount=$lowAmount |"
      " HIGH Qty=$highQty Amount=$highAmount",
    );

    // 4. Multiply totals with slot multiplier
    final int finalLowQty = lowQty * slotMultiplier;
    final double finalLowAmount = lowAmount * slotMultiplier;
    final int finalHighQty = highQty * slotMultiplier;
    final double finalHighAmount = highAmount * slotMultiplier;

    debugPrint(
      "Step 3 → Final Totals After Multiplier:"
      " LOW Qty=$finalLowQty Amount=$finalLowAmount |"
      " HIGH Qty=$finalHighQty Amount=$finalHighAmount",
    );

    // 5. Refund logic
    if (!isRefreshing) {
      debugPrint("Step 4 → Refund Logic Enabled");

      final double refundAmount = high ? finalHighAmount : finalLowAmount;

      debugPrint("Mode: ${high ? "HIGH" : "LOW"}");
      debugPrint("Calculated Refund Amount: $refundAmount");

      if (refundAmount > 0) {
        final double currentBalance = walletController.walletBalance.value;

        final double newBalance = currentBalance + refundAmount;

        debugPrint(
          "Wallet Before: $currentBalance | "
          "Wallet After Refund: $newBalance",
        );

        walletController.setBalance(newBalance);
      } else {
        debugPrint("Refund Skipped → Amount is 0");
      }
    } else {
      debugPrint("Step 4 → Refresh Mode: Refund Skipped");
    }

    // 6. Clearing controllers
    debugPrint("Step 5 → Clearing Controllers");
    debugPrint("ctrls count: ${ctrls.length}");
    debugPrint("headerCtrls count: ${headerCtrls.length}");
    debugPrint("rowCtrls count: ${rowCtrls.length}");

    for (final c in ctrls.values) {
      c.clear();
    }

    for (final c in headerCtrls.values) {
      c.clear();
    }

    for (final c in rowCtrls.values) {
      c.clear();
    }

    // 7. Clear quantity map
    debugPrint("Step 6 → Clearing cellQty (size: ${cellQty.length})");
    cellQty.clear();

    // 8. Reset selections
    debugPrint("Step 7 → Resetting selections and flags");

    selectedSeries_Set = {0};
    selectedRange_Set = {0};
    odd = false;
    even = false;

    // 9. Reset totals
    debugPrint("Step 8 → Resetting totals to 0");

    lowQty = 0;
    lowAmount = 0.0;
    highQty = 0;
    highAmount = 0.0;
    isFPChecked = false;
    // 10. Final recalculation
    recalc();
    debugPrint("Step 9 → Recalculation Done");

    debugPrint("Final Wallet Balance: ${walletController.walletBalance.value}");

    debugPrint("========== CLEAR END ==========");
  }

  // ─── Dispose ───────────────────────────────────────────────────────────────

  void dispose() {
    // for (final c in ctrls.values) c.dispose();
  }

  void clearAllControllers() {
    print("===== CLEAR ALL CONTROLLERS START =====");

    final int ctrlsCount = ctrls.length;
    final int headerCount = headerCtrls.length;
    final int rowCount = rowCtrls.length;

    print("ctrls count: $ctrlsCount");
    print("headerCtrls count: $headerCount");
    print("rowCtrls count: $rowCount");
    print("Total controllers: ${ctrlsCount + headerCount + rowCount}");

    // Clear ctrls
    for (final controller in ctrls.values) {
      // print("ctrls before clear: ${controller.text}");
      controller.clear();
    }

    // Clear headerCtrls
    for (final controller in headerCtrls.values) {
      // print("headerCtrls before clear: ${controller.text}");
      controller.clear();
    }

    // Clear rowCtrls
    for (final controller in rowCtrls.values) {
      // print("rowCtrls before clear: ${controller.text}");
      controller.clear();
    }

    print("===== CLEAR ALL CONTROLLERS END =====");
  }
}

class BettingGridController {
  final BettingGridModel model = BettingGridModel();

  Map<String, dynamic> _calculateTotals({int? row}) {
    final selections = model.collectAllNumbersForPrint();

    const List<int> multipliers = [1, 1, 2, 3, 5, 5, 10, 20, 25, 25];

    int totalQty = 0;
    double totalAmount = 0.0;

    for (final entry in selections.entries) {
      final int number = entry.key;
      int qty = entry.value;

      if (qty <= 0) continue;

      final int safeNumber = number % 10000;

      if (model.high) {
        // ✅ Hundreds digit (0–9)
        final int index = (safeNumber ~/ 100) % 10;

        if (row != null && index != row) continue;

        if (index < 0 || index >= multipliers.length) continue;

        final int multiplier = multipliers[index];

        // 🔥 Multiply QTY first
        final int finalQty = qty * multiplier;

        totalQty += finalQty;

        // Base cost in HIGH mode is always 2
        totalAmount += finalQty * 2.0;
      } else {
        final int seriesIndex = safeNumber ~/ 1000;

        if (row != null && seriesIndex != row) continue;

        totalQty += qty;
        totalAmount += qty * model.selectedPoint;
      }
    }

    return {
      'qty': totalQty,
      'amount': double.parse(totalAmount.toStringAsFixed(2)),
    };
  }

  // =====================================================
  Future<String> _getToken() async {
    final box = await Hive.openBox('app');
    return box.get('token', defaultValue: '') as String;
  }

  // =====================================================
  // BUILD API PAYLOAD (DO NOT CHANGE FORMAT)
  // =====================================================

  // Map<String, dynamic> buildPlaceBidPayload({
  //   String? slot, // for normal bet
  //   List<TimeOfDay>? advancedSlots, // for advanced bet
  // }) {
  //   final Map<String, int> allDatas2 = {};
  //   final Map<String, int> allDatas123 = {};
  //
  //   final int point = model.selectedPoint.toInt();
  //
  //   // ================= VALIDATION =================
  //   final bool isAdvanced = advancedSlots != null && advancedSlots.isNotEmpty;
  //
  //   if (!isAdvanced && (slot == null || slot.isEmpty)) {
  //     throw Exception("Slot is required for normal bet");
  //   }
  //
  //   // ================= FORMAT TIME =================
  //   String formatTime(TimeOfDay time) {
  //     final h = time.hour.toString().padLeft(2, '0');
  //     final m = time.minute.toString().padLeft(2, '0');
  //     return '$h:$m';
  //   }
  //
  //   // ================= BUILD SLOT FIELD =================
  //   String sloatValue;
  //
  //   if (isAdvanced) {
  //     final Map<String, String> slotMap = {
  //       for (int i = 0; i < advancedSlots.length; i++)
  //         i.toString(): formatTime(advancedSlots[i]),
  //     };
  //     sloatValue = jsonEncode(slotMap);
  //   } else {
  //     sloatValue = slot!;
  //   }
  //
  //   // ================= POINT MAP =================
  //   if (point > 0) {
  //     for (int series = 0; series < 10; series++) {
  //       for (int range = 0; range < model.ranges.length; range++) {
  //         allDatas123['c${series}_s${range}_point'] = point;
  //       }
  //     }
  //   }
  //
  //   // ================= BET DATA =================
  //   for (int series = 0; series < 10; series++) {
  //     for (int range = 0; range < model.ranges.length; range++) {
  //       final int base = series * 1000 + range * 100;
  //
  //       for (int row = 0; row < 10; row++) {
  //         for (int col = 0; col < 10; col++) {
  //           final int number = row * 10 + col;
  //
  //           final int qty =
  //               int.tryParse(
  //                 model._getCtrl(series, range, base + number).text,
  //               ) ??
  //               0;
  //
  //           if (qty > 0) {
  //             allDatas2['c${series}_s${range}_$number'] = qty * point;
  //           }
  //         }
  //       }
  //     }
  //   }
  //
  //   // ================= FINAL PAYLOAD =================
  //   return {
  //     'sloat': sloatValue,
  //     'a1': point.toString(),
  //     'advance_bet': isAdvanced ? "1" : "0",
  //     'all_datas2': jsonEncode(allDatas2),
  //     'all_datas123': jsonEncode(allDatas123),
  //   };
  // }

  Map<String, dynamic> buildPlaceBidPayload({
    String? slot,
    List<TimeOfDay>? advancedSlots,
  }) {
    final Map<String, int> allDatas2 = {};
    final Map<String, int> allDatas123 = {};

    final int point = model.selectedPoint.toInt();
    final bool isAdvanced = advancedSlots != null && advancedSlots.isNotEmpty;

    if (!isAdvanced && (slot == null || slot.isEmpty)) {
      throw Exception("Slot is required for normal bet");
    }

    // ================= FORMAT TIME =================
    String formatTime(TimeOfDay time) {
      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    // ================= BUILD SLOT =================
    String sloatValue;

    if (isAdvanced) {
      final Map<String, String> slotMap = {
        for (int i = 0; i < advancedSlots.length; i++)
          i.toString(): formatTime(advancedSlots[i]),
      };
      sloatValue = jsonEncode(slotMap);
    } else {
      sloatValue = slot!;
    }

    // ================= MULTIPLIERS (HIGH MODE) =================
    final List<int> multipliers = [1, 1, 2, 3, 5, 5, 10, 20, 25, 25];

    // ================= BUILD BET DATA =================
    for (int series = 0; series < 10; series++) {
      for (int range = 0; range < model.ranges.length; range++) {
        final int base = series * 1000 + range * 100;

        bool hasBetInThisCell = false;

        for (int row = 0; row < 10; row++) {
          for (int col = 0; col < 10; col++) {
            final int number = row * 10 + col;

            final controller = model._getCtrl(series, range, base + number);

            final int qty = int.tryParse(controller.text.trim()) ?? 0;

            if (qty <= 0) continue;

            hasBetInThisCell = true;

            int multiplier = 1;

            // 🔵 HIGH MODE
            if (model.high) {
              multiplier = multipliers[range];
            }

            final int totalAmount = qty * point * multiplier;

            allDatas2['c${series}_s${range}_$number'] = totalAmount;
          }
        }

        // ================= POINT MAP =================
        if (hasBetInThisCell && point > 0) {
          allDatas123['c${series}_s${range}_point'] = point;
        }
      }
    }

    // ================= FINAL PAYLOAD =================
    return {
      'sloat': sloatValue,
      'a1': point.toString(),
      'advance_bet': isAdvanced ? "1" : "0",
      'all_datas2': jsonEncode(allDatas2),
      'all_datas123': jsonEncode(allDatas123),
    };
  }

  /// 23_02_2026 10:30 pm
  /// uncomment if needed
  // Map<String, dynamic> buildPlaceBidPayload({
  //   String? slot,
  //   List<TimeOfDay>? advancedSlots,
  // }) {
  //   final Map<String, int> allDatas2 = {};
  //   final Map<String, int> allDatas123 = {};
  //
  //   final int point = model.selectedPoint.toInt();
  //   final bool isAdvanced = advancedSlots != null && advancedSlots.isNotEmpty;
  //
  //   if (!isAdvanced && (slot == null || slot.isEmpty)) {
  //     throw Exception("Slot is required for normal bet");
  //   }
  //
  //   // ================= FORMAT TIME =================
  //   String formatTime(TimeOfDay time) {
  //     final h = time.hour.toString().padLeft(2, '0');
  //     final m = time.minute.toString().padLeft(2, '0');
  //     return '$h:$m';
  //   }
  //
  //   // ================= BUILD SLOT =================
  //   String sloatValue;
  //
  //   if (isAdvanced) {
  //     final Map<String, String> slotMap = {
  //       for (int i = 0; i < advancedSlots.length; i++)
  //         i.toString(): formatTime(advancedSlots[i]),
  //     };
  //     sloatValue = jsonEncode(slotMap);
  //   } else {
  //     sloatValue = slot!;
  //   }
  //
  //   // ================= MULTIPLIERS =================
  //   final List<int> multipliers = [1, 1, 2, 3, 5, 5, 10, 20, 25, 25];
  //
  //   print(sloatValue);
  //   // ================= POINT MAP =================
  //   if (point > 0) {
  //     for (int series = 0; series < 10; series++) {
  //       for (int range = 0; range < model.ranges.length; range++) {
  //         allDatas123['c${series}_s${range}_point'] = point;
  //         /// allDatas123 fix this  model
  //         //                       ._getCtrl(series, range, base + number)
  //         //                       .text,use this logic proper code all code
  //       }
  //     }
  //   }
  //
  //   // ================= BET DATA =================
  //   for (int series = 0; series < 10; series++) {
  //     for (int range = 0; range < model.ranges.length; range++) {
  //       final int base = series * 1000 + range * 100;
  //
  //       for (int row = 0; row < 10; row++) {
  //         for (int col = 0; col < 10; col++) {
  //           final int number = row * 10 + col;
  //
  //           final int qty =
  //               int.tryParse(
  //                 model
  //                     ._getCtrl(series, range, base + number)
  //                     .text,
  //               ) ??
  //               0;
  //
  //           if (qty <= 0) continue;
  //
  //           int multiplier = 1;
  //
  //           // ✅ HIGH mode multiplier
  //           // if (model.high) {
  //           //   multiplier = multipliers[range];
  //           // }
  //
  //           final int totalAmount = qty * point * multiplier;
  //
  //           allDatas2['c${series}_s${range}_$number'] = totalAmount;
  //         }
  //       }
  //     }
  //   }
  //
  //   // ================= FINAL PAYLOAD =================
  //   return {
  //     'sloat': sloatValue,
  //     'a1': point.toString(),
  //     'advance_bet': isAdvanced ? "1" : "0",
  //     'all_datas2': jsonEncode(allDatas2),
  //     'all_datas123': jsonEncode(allDatas123),
  //   };
  // }

  // Future<void> handlePrint(
  //   BuildContext context,
  //   String slot,
  //   List<TimeOfDay> slots,
  //   String userId,
  // ) async {
  //   final now = DateTime.now();
  //
  //   print(now);
  //
  //   DateTime parseSlotTime(String slot) {
  //     final parts = slot.trim().split(' ');
  //     final timePart = parts[0];
  //     final period = parts[1].toUpperCase();
  //
  //     final timeSplit = timePart.split(':');
  //     int hour = int.parse(timeSplit[0]);
  //     final int minute = int.parse(timeSplit[1]);
  //
  //     if (period == "PM" && hour != 12) {
  //       hour += 12;
  //     } else if (period == "AM" && hour == 12) {
  //       hour = 0;
  //     }
  //
  //     return DateTime(now.year, now.month, now.day, hour, minute);
  //   }
  //
  //   // ================= VALIDATION =================
  //
  //   final DateTime gameStart = DateTime(now.year, now.month, now.day, 9, 45);
  //
  //   final DateTime gameEnd = DateTime(now.year, now.month, now.day, 21, 30);
  //
  //   // ✅ If advanced slots selected → validate each slot
  //   if (slots.isNotEmpty) {
  //     for (final time in slots) {
  //       final slotTime = DateTime(
  //         now.year,
  //         now.month,
  //         now.day,
  //         time.hour,
  //         time.minute,
  //       );
  //
  //       if (slotTime.isBefore(gameStart)) {
  //         showInfoDialog(
  //           context: context,
  //           title: "Game Not Started",
  //           subtitle: "One or more selected slots are before 09:45 AM.",
  //         );
  //         return;
  //       }
  //
  //       if (slotTime.isAfter(gameEnd)) {
  //         showInfoDialog(
  //           context: context,
  //           title: "Game Closed",
  //           subtitle: "One or more selected slots are after 09:30 PM.",
  //         );
  //         return;
  //       }
  //     }
  //   }
  //   // ✅ Single slot validation
  //   else {
  //     final DateTime slotTime = parseSlotTime(slot);
  //
  //     if (slotTime.isBefore(gameStart)) {
  //       showInfoDialog(
  //         context: context,
  //         title: "Game Not Started",
  //         subtitle: "Game Not Started. Please Wait till 9:45",
  //       );
  //       return;
  //     }
  //
  //     if (slotTime.isAfter(gameEnd)) {
  //       showInfoDialog(
  //         context: context,
  //         title: "Game Closed",
  //         subtitle: " Game Time Over. Please Come Back Tomorrow",
  //       );
  //       return;
  //     }
  //   }
  //
  //   // ================= EARLY VALIDATION =================
  //
  //   if (slot.isEmpty && slots.isEmpty) {
  //     showInfoDialog(
  //       context: context,
  //       title: "Information",
  //       subtitle: "Please select a draw time slot.",
  //     );
  //     return;
  //   }
  //
  //   final payload = buildPlaceBidPayload(
  //     slot: slots.isEmpty ? slot : null,
  //     advancedSlots: slots.isNotEmpty ? slots : null,
  //   );
  //
  //   print(payload);
  //
  //   final Map<String, dynamic> decoded = Map<String, dynamic>.from(
  //     jsonDecode(payload["all_datas2"]),
  //   );
  //
  //   final bool hasAnyValue = decoded.values.any(
  //     (v) => int.tryParse(v.toString()) != null && int.parse(v.toString()) > 0,
  //   );
  //
  //   if (!hasAnyValue) {
  //     showInfoDialog(
  //       context: context,
  //       title: "Information",
  //       subtitle: "Enter quantity for at least one number to continue.",
  //     );
  //     return;
  //   }
  //
  //   try {
  //     final token = await _getToken();
  //
  //     final request = http.MultipartRequest(
  //       'POST',
  //       Uri.parse('${ApiConstants.baseUrl}/place-bid'),
  //     );
  //
  //     request.headers['Authorization'] = 'Bearer $token';
  //
  //     payload.forEach((key, value) {
  //       request.fields[key] = value.toString();
  //     });
  //
  //     final streamedResponse = await request.send();
  //     final response = await http.Response.fromStream(streamedResponse);
  //
  //     if (response.statusCode != 200) {
  //       if (!context.mounted) return;
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text("Server error. Please try again."),
  //           backgroundColor: Color(0xFFC0392B),
  //         ),
  //       );
  //       return;
  //     }
  //
  //     final apiJson = jsonDecode(response.body);
  //
  //     if (apiJson['status'] != true) {
  //       if (!context.mounted) return;
  //       showInfoDialog(
  //         context: context,
  //         title: "Information",
  //         subtitle: apiJson['message'] ?? "Something went wrong",
  //       );
  //       return;
  //     }
  //
  //     final data = apiJson['data'];
  //
  //     List<String> ticketIds = [];
  //     if (data['parent_all'] is List &&
  //         (data['parent_all'] as List).isNotEmpty) {
  //       ticketIds = (data['parent_all'] as List)
  //           .map((e) => e.toString())
  //           .toList();
  //     }
  //
  //     List<String> ticketTimes = [];
  //     final walate2 = data['walate2'];
  //
  //     if (walate2 != null) {
  //       try {
  //         if (walate2.toString().startsWith('{')) {
  //           final decodedWalate = jsonDecode(walate2);
  //           ticketTimes = decodedWalate.values
  //               .map<String>((e) => e.toString())
  //               .toList();
  //         } else {
  //           ticketTimes = [walate2.toString()];
  //         }
  //       } catch (_) {
  //         ticketTimes = [walate2.toString()];
  //       }
  //     }
  //
  //     if (ticketTimes.isEmpty) {
  //       final fallbackTime =
  //           '${now.hour.toString().padLeft(2, '0')}:'
  //           '${now.minute.toString().padLeft(2, '0')}';
  //
  //       ticketTimes = List.filled(
  //         ticketIds.isNotEmpty ? ticketIds.length : 1,
  //         fallbackTime,
  //       );
  //     }
  //
  //     final Map<String, int> selections = {};
  //     int totalQty = 0;
  //     int totalAmount = 0;
  //
  //     final int point = model.selectedPoint.toInt();
  //     const List<int> multipliers = [1, 1, 2, 3, 5, 5, 10, 20, 25, 25];
  //
  //     decoded.forEach((key, value) {
  //       final parts = key.split('_');
  //
  //       final int series = int.parse(parts[0].substring(1));
  //       final int range = int.parse(parts[1].substring(1));
  //       final int number = int.parse(parts[2]);
  //
  //       final String fullNumber = (series * 1000 + range * 100 + number)
  //           .toString()
  //           .padLeft(4, "0");
  //
  //       final int amount = int.parse(value.toString());
  //
  //       int qty = 0;
  //
  //       if (model.high) {
  //         if (range >= 0 && range < multipliers.length) {
  //           final int costPerCell =
  //               2 * multipliers[range]; // proper range from 0 to 9
  //           qty = amount ~/ costPerCell;
  //         }
  //       } else {
  //         qty = amount ~/ point;
  //       }
  //
  //       if (qty > 0) {
  //         int finalQty = qty;
  //
  //         if (model.high) {
  //           // Extract hundreds digit (0–9)
  //           final int index = int.parse(fullNumber[1]);
  //
  //           if (index >= 0 && index < multipliers.length) {
  //             finalQty = qty * multipliers[index];
  //           }
  //         }
  //
  //         selections[fullNumber] = finalQty;
  //
  //         totalQty += finalQty;
  //         totalAmount +=
  //             amount; // keep original amount (do not change backend value)
  //       }
  //     });
  //
  //     if (selections.isEmpty) {
  //       if (!context.mounted) return;
  //       ScaffoldMessenger.of(
  //         context,
  //       ).showSnackBar(const SnackBar(content: Text("No numbers selected")));
  //       return;
  //     }
  //
  //     List<int> ticketAmounts;
  //
  //     if (ticketIds.isNotEmpty) {
  //       ticketAmounts = List.generate(ticketIds.length, (_) => totalAmount);
  //     } else {
  //       ticketAmounts = [totalAmount];
  //     }
  //
  //     debugPrint("════════════ PRINT DEBUG ════════════");
  //     debugPrint("Selections → $selections");
  //     debugPrint("Total Qty → $totalQty");
  //     debugPrint("Total Amount → $totalAmount");
  //     debugPrint("Ticket IDs → $ticketIds");
  //     debugPrint("══════════════════════════════════════");
  //
  //     await TicketPrintService.printTicket(
  //       context: context,
  //       selections: selections,
  //       ticketIds: ticketIds,
  //       ticketTimes: ticketTimes,
  //       date:
  //           '${now.day.toString().padLeft(2, '0')}-'
  //           '${now.month.toString().padLeft(2, '0')}-'
  //           '${now.year}',
  //       totalQty: totalQty,
  //       ticketsAmounts: ticketAmounts,
  //       userId: userId,
  //     );
  //
  //     model.clearAllControllers();
  //     model.clear(slots, isRefreshing: true);
  //   } catch (e, s) {
  //     debugPrint("HandlePrint Error: $e\n$s");
  //
  //     if (!context.mounted) return;
  //
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text("Something went wrong. Please try again."),
  //         backgroundColor: Color(0xFFC0392B),
  //       ),
  //     );
  //   }
  // }

  Future<Map<String, dynamic>> handlePrint(
    BuildContext context,
    String slot,
    List<TimeOfDay> slots,
    String userId,
  ) async {
    final now = DateTime.now();

    // ================= SLOT VALIDATION FIRST =================

    if (slot.isEmpty && slots.isEmpty) {
      return {"success": false, "failedAt": "slot_missing"};
    }

    DateTime parseSlotTime(String slot) {
      final parts = slot.trim().split(' ');
      final timePart = parts[0];
      final period = parts.length > 1 ? parts[1].toUpperCase() : "";

      final timeSplit = timePart.split(':');
      int hour = int.parse(timeSplit[0]);
      final int minute = int.parse(timeSplit[1]);

      if (period == "PM" && hour != 12) hour += 12;
      if (period == "AM" && hour == 12) hour = 0;

      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    final DateTime gameStart = DateTime(now.year, now.month, now.day, 9, 45);

    final DateTime gameEnd = DateTime(now.year, now.month, now.day, 21, 30);

    // ================= SLOT VALIDATION WITH DEBUG =================

    debugPrint("════════ SLOT VALIDATION START ════════");
    debugPrint("Now        → $now");
    debugPrint("Game Start → $gameStart");
    debugPrint("Game End   → $gameEnd");
    debugPrint("Slots List → $slots");
    debugPrint("Single Slot→ $slot");

    if (slots.isNotEmpty) {
      debugPrint("Mode → ADVANCED SLOTS");

      for (final time in slots) {
        final slotTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        debugPrint("Checking Slot → $slotTime");

        if (slotTime.isBefore(gameStart)) {
          debugPrint("❌ FAILED → Slot before game start");
          debugPrint("════════ SLOT VALIDATION END ════════");
          return {
            "success": false,
            "failedAt": "game_not_started",
            "slotTime": slotTime.toString(),
          };
        }

        if (slotTime.isAfter(gameEnd)) {
          debugPrint("❌ FAILED → Slot after game end");
          debugPrint("════════ SLOT VALIDATION END ════════");
          return {
            "success": false,
            "failedAt": "game_closed",
            "slotTime": slotTime.toString(),
          };
        }

        debugPrint("✅ Slot OK → $slotTime");
      }

      debugPrint("✅ All Advanced Slots Valid");
    } else {
      debugPrint("Mode → SINGLE SLOT");

      final slotTime = parseSlotTime(slot);

      debugPrint("Parsed Slot → $slotTime");

      if (slotTime.isBefore(gameStart)) {
        debugPrint("❌ FAILED → Slot before game start");
        debugPrint("════════ SLOT VALIDATION END ════════");
        return {
          "success": false,
          "failedAt": "game_not_started",
          "slotTime": slotTime.toString(),
        };
      }

      if (slotTime.isAfter(gameEnd)) {
        debugPrint("❌ FAILED → Slot after game end");
        debugPrint("════════ SLOT VALIDATION END ════════");
        return {
          "success": false,
          "failedAt": "game_closed",
          "slotTime": slotTime.toString(),
        };
      }

      debugPrint("✅ Single Slot OK → $slotTime");
    }

    debugPrint("════════ SLOT VALIDATION PASSED ════════");

    // ================= PAYLOAD BUILD =================

    final payload = buildPlaceBidPayload(
      slot: slots.isEmpty ? slot : null,
      advancedSlots: slots.isNotEmpty ? slots : null,
    );

    if (!payload.containsKey("all_datas2")) {
      return {"success": false, "failedAt": "invalid_payload"};
    }

    final Map<String, dynamic> decoded = Map<String, dynamic>.from(
      jsonDecode(payload["all_datas2"]),
    );

    final bool hasAnyValue = decoded.values.any(
      (v) => int.tryParse(v.toString()) != null && int.parse(v.toString()) > 0,
    );

    if (!hasAnyValue) {
      return {"success": false, "failedAt": "empty_selection"};
    }

    // ================= LOADING DIALOG =================

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
          decoration: BoxDecoration(
            color: const Color(0xFF1F1F1F),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2.8,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 18),
              Text(
                "Printing ticket...",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      final token = await _getToken();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/place-bid'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      payload.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(response.body);
      if (response.statusCode != 200) {
        Get.back();
        return {"success": false, "failedAt": "server_error"};
      }

      final apiJson = jsonDecode(response.body);

      if (apiJson['status'] != true) {
        Get.back();
        return {
          "success": false,
          "failedAt": "api_rejected",
          "message": apiJson["message"],
        };
      }

      final data = apiJson['data'];

      // ================= TICKET IDS =================

      List<String> ticketIds = [];
      if (data['parent_all'] is List) {
        ticketIds = (data['parent_all'] as List)
            .map((e) => e.toString())
            .toList();
      }

      // ================= TICKET TIMES =================

      List<String> ticketTimes = [];

      if (data['walate2'] != null) {
        try {
          if (data['walate2'].toString().startsWith('{')) {
            final decodedWalate = jsonDecode(data['walate2']);
            ticketTimes = decodedWalate.values
                .map<String>((e) => e.toString())
                .toList();
          } else {
            ticketTimes = [data['walate2'].toString()];
          }
        } catch (_) {
          ticketTimes = [data['walate2'].toString()];
        }
      }

      if (ticketTimes.isEmpty) {
        final fallbackTime =
            '${now.hour.toString().padLeft(2, '0')}:'
            '${now.minute.toString().padLeft(2, '0')}';

        ticketTimes = List.filled(
          ticketIds.isNotEmpty ? ticketIds.length : 1,
          fallbackTime,
        );
      }

      // ================= BUILD SELECTIONS =================

      final Map<String, int> selections = {};
      int totalQty = 0;
      int totalAmount = 0;

      final int point = model.selectedPoint.toInt();

      const List<int> multipliers = [1, 1, 2, 3, 5, 5, 10, 20, 25, 25];

      decoded.forEach((key, value) {
        final parts = key.split('_');

        final int series = int.parse(parts[0].substring(1));
        final int range = int.parse(parts[1].substring(1));
        final int number = int.parse(parts[2]);

        final String fullNumber = (series * 1000 + range * 100 + number)
            .toString()
            .padLeft(4, "0");

        final int amount = int.parse(value.toString());

        int qty = 0;

        if (model.high) {
          if (range >= 0 && range < multipliers.length) {
            final int costPerCell = 2 * multipliers[range];
            qty = amount ~/ costPerCell;
          }
        } else {
          qty = amount ~/ point;
        }

        if (qty > 0) {
          int finalQty = qty;

          if (model.high) {
            final int index = int.parse(fullNumber[1]);
            if (index >= 0 && index < multipliers.length) {
              finalQty = qty * multipliers[index];
            }
          }

          selections[fullNumber] = finalQty;

          totalQty += finalQty;
          totalAmount += amount;
        }
      });

      if (selections.isEmpty) {
        Get.back();
        return {"success": false, "failedAt": "no_selection"};
      }

      final List<int> ticketAmounts = ticketIds.isNotEmpty
          ? List.generate(ticketIds.length, (_) => totalAmount)
          : [totalAmount];

      // ================= PRINT ONE BY ONE (ADVANCED SAFE) =================

      for (int i = 0; i < ticketIds.length; i++) {
        await TicketPrintService.printTicket(
          context: context,
          selections: selections,
          ticketIds: [ticketIds[i]],
          ticketTimes: [
            i < ticketTimes.length ? ticketTimes[i] : ticketTimes.first,
          ],
          date:
              '${now.day.toString().padLeft(2, '0')}-'
              '${now.month.toString().padLeft(2, '0')}-'
              '${now.year}',
          totalQty: totalQty,
          ticketsAmounts: [ticketAmounts[i]],
          userId: userId,
        );
      }

      model.clearAllControllers();
      model.clear(slots, isRefreshing: true);

      Get.back();

      return {"success": true};
    } catch (e) {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      return {"success": false, "failedAt": "exception"};
    }
  }

  // =====================================================
  // PDF SUPPORT METHODS
  // =====================================================
  List<pw.Widget> _buildTicketRows(Map<int, int> selections) {
    return selections.entries.map((e) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                e.key.toString().padLeft(4, '0'),
                style: pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                e.value.toString(),
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 8)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  // =====================================================
  // CLEANUP
  // =====================================================
  void dispose() => model.dispose();
}

class BettingGridScreen extends StatefulWidget {
  int limitUpdate;
  final String slot;
  final String id;

  BettingGridScreen({
    super.key,
    required this.limitUpdate,
    required this.slot,
    required this.id,
  });

  @override
  State<BettingGridScreen> createState() => _BettingGridScreenState();
}

class _BettingGridScreenState extends State<BettingGridScreen> {
  late BettingGridController controller;
  final homeController = HomeController();
  bool isClaiming = false;

  int? _selectedIndex; // null: none, 0: Page Up, 1: Page Down, 2: All
  List<TimeOfDay> slots = [];
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  bool _isClearing = false;

  final Map<int, FocusNode> _headerFocusNodes = {};
  final Map<int, bool> _headerHoverState = {};
  final Map<int, FocusNode> _rowFocusNodes = {};
  final Map<int, bool> _rowHoverState = {};

  final Map<int, FocusNode> _cellFocusNodes = {};

  FocusNode _getFocusNode(int n) {
    return _cellFocusNodes.putIfAbsent(n, () => FocusNode());
  }

  int get _totalNumbers =>
      controller.model.visibleEnd - controller.model.visibleStart + 1;

  int get _colCount => 10;

  int get _rowCount => (_totalNumbers / _colCount).ceil();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    controller.dispose();
    super.dispose();
  }

  final RefreshController refreshController = Get.put(RefreshController());

  @override
  void initState() {
    super.initState();

    HardwareKeyboard.instance.addHandler(_handleKey);

    controller = Get.put(BettingGridController());

    print("Limit Update : ${widget.limitUpdate}");
    controller.model.limitValue = widget.limitUpdate;

    /// Listen using ever
    ever(refreshController.isRefreshing, (value) {
      if (value == true) {
        controller.model.clear(["1"], isRefreshing: value);
      }
    });
  }

  bool _handleKey(KeyEvent e) {
    if (e is! KeyDownEvent) return false;

    if (e.logicalKey == LogicalKeyboardKey.f6) {
      debugPrint("F6 Pressed → Print Ticket");

      _handlePrintFromKey(); // 🔥 call async method separately
      return true;
    }

    if (e.logicalKey == LogicalKeyboardKey.f7) {
      debugPrint("F7 Pressed → Clear");
      controller.model.clear(slots);
      return true;
    }

    if (e.logicalKey == LogicalKeyboardKey.f5) {
      debugPrint("F5 Pressed → Refresh & Clear");
      controller.model.clear(slots, isRefreshing: true);
      refreshController.refreshingData();
      return true;
    }

    return false;
  }

  Future<void> _handlePrintFromKey() async {
    final result = await controller.handlePrint(
      context,
      widget.slot,
      slots,
      widget.id,
    );

    if (result["success"] == true) {
      showInfoDialog(
        context: context,
        title: "Success",
        subtitle: "Ticket printed successfully.",
      );
      return;
    }

    final failedAt = result["failedAt"];

    switch (failedAt) {
      case "game_not_started":
        showInfoDialog(
          context: context,
          title: "Game Not Started",
          subtitle: "Game will start at 09:45 AM. Please wait.",
        );
        break;

      case "game_closed":
        showInfoDialog(
          context: context,
          title: "Game Closed",
          subtitle: "Today's game time is over. Please come tomorrow.",
        );
        break;

      case "slot_missing":
        showInfoDialog(
          context: context,
          title: "Slot Required",
          subtitle: "Please select a draw time slot.",
        );
        break;

      case "empty_selection":
        showInfoDialog(
          context: context,
          title: "No Quantity",
          subtitle: "Enter quantity for at least one number.",
        );
        break;

      case "no_selection":
        showInfoDialog(
          context: context,
          title: "No Numbers",
          subtitle: "No valid numbers selected.",
        );
        break;

      case "server_error":
        showInfoDialog(
          context: context,
          title: "Server Error",
          subtitle: "Server error occurred. Please try again.",
        );
        break;

      case "api_rejected":
        showInfoDialog(
          context: context,
          title: "Request Failed",
          subtitle: result["message"],
        );
        break;

      case "exception":
        showInfoDialog(
          context: context,
          title: "Unexpected Error",
          subtitle: "Something went wrong. Please try again.",
        );
        break;

      default:
        showInfoDialog(
          context: context,
          title: "Error",
          subtitle: "Unknown error occurred.",
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Column(
        children: [
          _seriesBar(),
          _topControls(),
          // Option 1: Using Expanded (RECOMMENDED - Simplest)
          // Expanded(
          //   child: Scrollbar(
          //     controller: _verticalController,
          //     thumbVisibility: true,
          //     child: SingleChildScrollView(
          //       controller: _verticalController,
          //       scrollDirection: Axis.vertical,
          //       child: Scrollbar(
          //         controller: _horizontalController,
          //         thumbVisibility: true,
          //         child: SingleChildScrollView(
          //           controller: _horizontalController,
          //           scrollDirection: Axis.horizontal,
          //           child: SizedBox(
          //             width: MediaQuery.of(context).size.width,
          //             child: _grid(),
          //           ),
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          _grid(),

          _bottomSummary(),
          SizedBox(height: 4),
          _bottomButtons(widget.id),
          SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _seriesBar() {
    const double barHeight = 34;

    return SizedBox(
      height: barHeight,
      width: double.infinity,
      child: Row(
        children: [
          // ===== LEFT GREEN LABEL =====
          Container(
            width: 110,
            height: barHeight,
            alignment: Alignment.center,
            color: const Color(0xFF6FBF2E),
            child: const Text(
              'Series',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          // ===== RIGHT ORANGE SECTION =====
          Expanded(
            child: Container(
              height: barHeight,
              color: const Color(0xFFE98A1D),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ===== ALL =====
                  _seriesItem(
                    label: 'All',
                    checked: controller.model.selectedSeries_Set.length == 10,
                    onLabelTap: () => _toggleAll(),
                    onCheckTap: () => _toggleAll(),
                  ),

                  const SizedBox(width: 12),

                  // ===== SERIES 0–9 =====
                  ...List.generate(10, (i) {
                    final selected = controller.model.selectedSeries_Set
                        .contains(i);

                    return _seriesItem(
                      label:
                          '${(i * 1000).toString().padLeft(4, '0')}-'
                          '${(i * 1000 + 999).toString().padLeft(4, '0')}',
                      checked: selected,

                      // LABEL → single select + focus
                      onLabelTap: () {
                        setState(() {
                          controller.model.selectedSeries_Set
                            ..clear()
                            ..add(i);

                          controller.model.selectedSeries = i;
                          controller.model.focusSeries(i);
                          controller.model.indexController.setIndex(i);
                          controller.model.recalc();
                        });
                      },

                      // CHECKBOX → multi select with safe focus handling
                      onCheckTap: () {
                        setState(() {
                          final set = controller.model.selectedSeries_Set;

                          if (set.contains(i)) {
                            // keep at least one
                            if (set.length > 1) {
                              set.remove(i);

                              // if removed focused one → shift focus
                              if (controller.model.selectedSeries == i) {
                                final newFocus = set.first;
                                controller.model.selectedSeries = newFocus;
                                controller.model.focusSeries(newFocus);
                                controller.model.indexController.setIndex(
                                  newFocus,
                                );
                              }
                            }
                          } else {
                            set.add(i);

                            // optional: focus new selection
                            controller.model.selectedSeries = i;
                            controller.model.focusSeries(i);
                            controller.model.indexController.setIndex(i);
                          }

                          controller.model.recalc();
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleAll() {
    setState(() {
      controller.model.toggleAllSeries();

      final set = controller.model.selectedSeries_Set;

      if (set.isNotEmpty) {
        final first = set.first;
        controller.model.selectedSeries = first;
        controller.model.focusSeries(first);
        controller.model.indexController.setIndex(first);
      }

      controller.model.recalc();
    });
  }

  Widget _seriesItem({
    required String label,
    required bool checked,
    required VoidCallback onLabelTap,
    required VoidCallback onCheckTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Transform.scale(
            scale: 0.85,
            child: Checkbox(
              value: checked,
              onChanged: (_) => onCheckTap(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,

              activeColor: Colors.blue,
              checkColor: Colors.white,

              fillColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.blue;
                }
                return Colors.white;
              }),

              side: const BorderSide(color: Colors.black, width: 1.2),
            ),
          ),
        ),

        const SizedBox(width: 2),

        GestureDetector(
          onTap: onLabelTap,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  // ===================== TOP CONTROLS =====================
  Widget _topControls() {
    const double controlHeight = 25;
    const hGap = SizedBox(width: 10);

    void printRangeDebug() {
      debugPrint("------ RANGE DEBUG ------");
      debugPrint("High => ${controller.model.high}");
      debugPrint("Low  => ${controller.model.low}");
      debugPrint("-------------------------");
    }

    Future<void> switchToHigh() async {
      if (controller.model.high) return; // already in HIGH, do nothing
      await controller.model.clear([]); // refund + clear everything
      setState(() {
        controller.model.high = true;
        controller.model.low = false;
      });
      printRangeDebug();
    }

    Future<void> switchToLow() async {
      if (controller.model.low) return; // already in LOW, do nothing
      await controller.model.clear([]); // refund + clear everything
      setState(() {
        controller.model.low = true;
        controller.model.high = false;
      });
      printRangeDebug();
    }

    return SizedBox(
      height: controlHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ================= HIGH / LOW =================
          SizedBox(
            width: 200,
            height: controlHeight,
            child: Row(
              children: [
                _btn(
                  'High',
                  controller.model.high
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.blue,
                  controlHeight,
                  switchToHigh,
                ),
                hGap,
                _btn(
                  'Low',
                  controller.model.high
                      ? Colors.lightBlue
                      : Colors.lightBlue.withOpacity(0.3),
                  controlHeight,
                  switchToLow,
                ),
              ],
            ),
          ),
          const Spacer(),

          // ================= EVEN / ODD =================
          _check('Even', controller.model.even, controlHeight, () {
            setState(controller.model.toggleEven);
          }),
          hGap,
          _check('Odd', controller.model.odd, controlHeight, () {
            setState(controller.model.toggleOdd);
          }),

          const Spacer(),

          // ================= FP + RESULT =================
          SizedBox(
            height: controlHeight,
            width: 200,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.yellow.shade300,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade400),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _fpCheckbox(controlHeight),
                  const SizedBox(width: 8),
                  _btn(
                    'Show Result',
                    Colors.yellow.shade300,
                    controlHeight,
                    () {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierColor: Colors.black.withOpacity(0.45),
                        builder: (_) => const ResultDialog(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= BUTTON =================
  Widget _btn(String text, Color bg, double height, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          alignment: Alignment.center,
          color: bg,
          child: Text(
            text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  // ================= CHECK =================
  Widget _check(String text, bool checked, double height, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: checked ? Colors.blue : Colors.white,
                border: Border.all(color: Colors.black),
              ),
              child: checked
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ================= FP CHECKBOX =================
  Widget _fpCheckbox(double height) {
    return GestureDetector(
      onTap: () {
        setState(() {
          controller.model.isFPChecked = !controller.model.isFPChecked;
        });
      },
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                color: controller.model.isFPChecked
                    ? Colors.blue
                    : Colors.white,
              ),
              child: controller.model.isFPChecked
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 6),
            const Text(
              'FP',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // ================= RANGE BUTTON =================
  Widget _buildButton(
    int index,
    String label,
    int flex, {
    bool showCheckbox = false,
  }) {
    final bool isSelected = _selectedIndex == index;
    final bool isHigh = controller.model.high;

    return Expanded(
      flex: flex,
      child: InkWell(
        // 🔒 BLOCK NAVIGATION IN HIGH MODE
        onTap: isHigh
            ? null
            : () {
                setState(() {
                  _selectedIndex = index;
                });

                switch (index) {
                  case 0:
                    controller.model.pageRange(false);
                    break;

                  case 1:
                    controller.model.pageRange(true);
                    break;

                  case 2:
                    final model = controller.model;

                    if (model.selectedRange_Set.length == model.ranges.length) {
                      model.selectedRange_Set
                        ..clear()
                        ..add(model.selectedRange);
                    } else {
                      model.selectedRange_Set
                        ..clear()
                        ..addAll(List.generate(model.ranges.length, (i) => i));
                    }

                    model.recalc();
                    break;
                }
              },
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.black12 : Colors.white,
            border: Border.all(color: Colors.black.withOpacity(.4), width: .6),
          ),
          child: showCheckbox
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value:
                          controller.model.selectedRange_Set.length ==
                          controller.model.ranges.length,
                      onChanged: null, // stays visual only
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  // ===================== GRID =====================
  Widget _grid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [_leftPanel(), _numberGrid()],
    );
  }

  // ===================== LEFT PANEL =====================
  // Widget _leftPanel() {
  //   return SizedBox(
  //     width: 330,
  //     child: Column(
  //       children: [
  //         // ================= HEADER =================
  //         SizedBox(
  //           height: BettingGridModel.headerH,
  //           child: Row(
  //             children: [
  //               _buildButton(0, 'Page Up', 2),
  //               _buildButton(1, 'Page Down', 2),
  //               _buildButton(2, 'All', 2, showCheckbox: true),
  //             ],
  //           ),
  //         ),
  //
  //         // ================= RANGE LIST =================
  //         Column(
  //           children: List.generate(controller.model.ranges.length, (i) {
  //             final r = controller.model.ranges[i];
  //
  //             final bool rangeActive = controller.model.selectedRange_Set
  //                 .contains(i);
  //
  //             final int start = controller.model.seriesStart + (i * 100);
  //             final int end = start + 99;
  //
  //             final int colorIndex =
  //                 int.parse(start.toString().padLeft(4, '0')[0]) %
  //                 controller.model.colors.length;
  //
  //             final Color rangeColor = controller.model.colors[colorIndex];
  //
  //             final List<int> multipliers = [1, 1, 2, 3, 5, 5, 10, 20, 25, 25];
  //
  //             final List<int> amounts = [
  //               180,
  //               180,
  //               360,
  //               540,
  //               900,
  //               900,
  //               1800,
  //               3600,
  //               4500,
  //               4500,
  //             ];
  //
  //             return InkWell(
  //               onTap: () {
  //                 setState(() {
  //                   controller.model.selectedRange = i;
  //                   controller.model.selectedRange_Set.clear();
  //                   controller.model.selectedRange_Set.add(i);
  //
  //                   controller.model.visibleStart =
  //                       controller.model.seriesStart + (i * 100);
  //
  //                   controller.model.visibleEnd =
  //                       controller.model.visibleStart + 99;
  //
  //                   controller.model.headerCtrls.clear();
  //                   controller.model.rowCtrls.clear();
  //                   controller.model.recalc();
  //                 });
  //               },
  //               child: Container(
  //                 height: BettingGridModel.cellH + 4,
  //                 decoration: BoxDecoration(
  //                   border: Border(
  //                     bottom: BorderSide(
  //                       color: Colors.black.withOpacity(.2),
  //                       width: .3,
  //                     ),
  //                   ),
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     // ================= RANGE LABEL =================
  //                     Expanded(
  //                       flex: 2,
  //                       child: Container(
  //                         color: rangeActive ? rangeColor : Colors.transparent,
  //                         padding: const EdgeInsets.symmetric(horizontal: 8),
  //                         alignment: Alignment.centerLeft,
  //                         child: Text(
  //                           '${start.toString().padLeft(4, '0')}-${end.toString().padLeft(4, '0')}',
  //                           style: const TextStyle(
  //                             fontSize: 12.5, // 🔥 increased
  //                             fontWeight: FontWeight.w700,
  //                           ),
  //                         ),
  //                       ),
  //                     ),
  //
  //                     // ================= HIGH MODE =================
  //                     if (controller.model.high) ...[
  //                       Expanded(
  //                         flex: 2,
  //                         child: Container(
  //                           color: r.color,
  //                           child: Row(
  //                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                             children: [
  //                               Transform.scale(
  //                                 scale: 0.75, // 🔥 better visibility
  //                                 child: Checkbox(
  //                                   value: rangeActive,
  //                                   onChanged: (_) {
  //                                     setState(() {
  //                                       if (controller.model.selectedRange_Set
  //                                           .contains(i)) {
  //                                         controller.model.selectedRange_Set
  //                                             .remove(i);
  //                                       } else {
  //                                         controller.model.selectedRange_Set
  //                                             .add(i);
  //                                       }
  //                                       controller.model.recalc();
  //                                     });
  //                                   },
  //                                   materialTapTargetSize:
  //                                       MaterialTapTargetSize.shrinkWrap,
  //                                   visualDensity: VisualDensity.compact,
  //                                 ),
  //                               ),
  //                               Text(
  //                                 '(Pts 2×${multipliers[i]})',
  //                                 style: const TextStyle(
  //                                   fontSize: 12, // 🔥 increased
  //                                   fontWeight: FontWeight.w700,
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ),
  //                       Expanded(
  //                         flex: 1,
  //                         child: Container(
  //                           color: r.color,
  //                           alignment: Alignment.center,
  //                           child: Text(
  //                             amounts[i].toString(),
  //                             style: const TextStyle(
  //                               fontSize: 12.5, // 🔥 increased
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                         ),
  //                       ),
  //                     ]
  //                     // ================= LOW MODE =================
  //                     else ...[
  //                       // ================= RANGE CHECKBOX =================
  //                       Expanded(
  //                         flex: 2,
  //                         child: Container(
  //                           color: r.color,
  //                           child: Row(
  //                             mainAxisAlignment: MainAxisAlignment.center,
  //                             children: [
  //                               Transform.scale(
  //                                 scale: 0.75,
  //                                 child: Checkbox(
  //                                   value: rangeActive,
  //                                   onChanged: (_) {
  //                                     setState(() {
  //                                       if (controller.model.selectedRange_Set
  //                                           .contains(i)) {
  //                                         controller.model.selectedRange_Set
  //                                             .remove(i);
  //                                       } else {
  //                                         controller.model.selectedRange_Set
  //                                             .add(i);
  //                                       }
  //                                       controller.model.recalc();
  //                                     });
  //                                   },
  //                                   materialTapTargetSize:
  //                                       MaterialTapTargetSize.shrinkWrap,
  //                                   visualDensity: VisualDensity.compact,
  //                                 ),
  //                               ),
  //                               Text(
  //                                 '(pt ${controller.model.selectedPoint.toInt()})',
  //                                 style: const TextStyle(
  //                                   fontSize: 12.5,
  //                                   fontWeight: FontWeight.w700,
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ),
  //                       ),
  //
  //                       // ================= POINT RADIO =================
  //                       Expanded(
  //                         flex: 2,
  //                         child: Container(
  //                           color: r.color,
  //                           alignment: Alignment.center,
  //                           child: r.points == 0
  //                               ? const SizedBox.shrink()
  //                               : Row(
  //                                   mainAxisAlignment: MainAxisAlignment.center,
  //                                   children: [
  //                                     Transform.scale(
  //                                       scale: 0.8,
  //                                       child: Radio<double>(
  //                                         value: r.points.toDouble(),
  //                                         // ✅ correct value
  //                                         groupValue:
  //                                             controller.model.selectedPoint,
  //                                         // ✅ match same type
  //                                         onChanged: (value) {
  //                                           setState(() {
  //                                             controller.model.selectedPoint =
  //                                                 value!;
  //                                             controller.model.recalc();
  //                                           });
  //                                         },
  //                                         materialTapTargetSize:
  //                                             MaterialTapTargetSize.shrinkWrap,
  //                                         visualDensity: VisualDensity.compact,
  //                                       ),
  //                                     ),
  //                                     const SizedBox(width: 6),
  //                                     Text(
  //                                       r.points.toStringAsFixed(2),
  //                                       style: const TextStyle(
  //                                         fontSize: 14.5,
  //                                         fontWeight: FontWeight.w700,
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                         ),
  //                       ),
  //                     ],
  //                   ],
  //                 ),
  //               ),
  //             );
  //           }),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ===================== NUMBER GRID =====================

  Widget _leftPanel() {
    return SizedBox(
      width: 330,
      child: Column(
        children: [
          // ================= HEADER =================
          SizedBox(
            height: BettingGridModel.headerH,
            child: Row(
              children: [
                _buildButton(0, 'Page Up', 2),
                _buildButton(1, 'Page Down', 2),
                _buildButton(2, 'All', 2, showCheckbox: true),
              ],
            ),
          ),

          // ================= RANGE LIST =================
          Column(
            children: List.generate(controller.model.ranges.length, (i) {
              final r = controller.model.ranges[i];

              final bool rangeActive = controller.model.selectedRange_Set
                  .contains(i);

              final int start = controller.model.seriesStart + (i * 100);
              final int end = start + 99;

              final int colorIndex =
                  int.parse(start.toString().padLeft(4, '0')[0]) %
                  controller.model.colors.length;

              final Color rangeColor = controller.model.colors[colorIndex];

              final List<int> multipliers = [1, 1, 2, 3, 5, 5, 10, 20, 25, 25];

              final List<int> amounts = [
                180,
                180,
                360,
                540,
                900,
                900,
                1800,
                3600,
                4500,
                4500,
              ];

              return InkWell(
                // 🔥 BLOCK NAVIGATION IN HIGH MODE
                onTap: controller.model.high
                    ? null
                    : () {
                        setState(() {
                          controller.model.selectedRange = i;
                          controller.model.selectedRange_Set.clear();
                          controller.model.selectedRange_Set.add(i);

                          controller.model.visibleStart =
                              controller.model.seriesStart + (i * 100);

                          controller.model.visibleEnd =
                              controller.model.visibleStart + 99;

                          controller.model.headerCtrls.clear();
                          controller.model.rowCtrls.clear();
                          controller.model.recalc();
                        });
                      },
                child: Container(
                  height: BettingGridModel.cellH + 4,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black.withOpacity(.2),
                        width: .3,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // ================= RANGE LABEL =================
                      Expanded(
                        flex: 2,
                        child: Container(
                          color: rangeActive ? rangeColor : Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${start.toString().padLeft(4, '0')}-${end.toString().padLeft(4, '0')}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),

                      // ================= HIGH MODE =================
                      if (controller.model.high) ...[
                        Expanded(
                          flex: 2,
                          child: Container(
                            color: r.color,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Transform.scale(
                                  scale: 0.8,
                                  child: Checkbox(
                                    value: rangeActive,
                                    onChanged: (_) {
                                      setState(() {
                                        if (controller.model.selectedRange_Set
                                            .contains(i)) {
                                          controller.model.selectedRange_Set
                                              .remove(i);
                                        } else {
                                          controller.model.selectedRange_Set
                                              .add(i);
                                        }
                                        controller.model.recalc();
                                      });
                                    },
                                    fillColor:
                                        MaterialStateProperty.resolveWith((
                                          states,
                                        ) {
                                          if (states.contains(
                                            MaterialState.selected,
                                          )) {
                                            return Colors.blue;
                                          }
                                          return Colors.white;
                                        }),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    activeColor: Colors.blue,
                                    checkColor: Colors.white,
                                  ),
                                ),
                                Text(
                                  '(Pts 2×${multipliers[i]})',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            color: r.color,
                            alignment: Alignment.center,
                            child: Text(
                              amounts[i].toString(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ]
                      // ================= LOW MODE =================
                      else ...[
                        Expanded(
                          flex: 2,
                          child: Container(
                            color: r.color,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Transform.scale(
                                  scale: 0.8,
                                  child: Checkbox(
                                    value: rangeActive,
                                    onChanged: (_) {
                                      setState(() {
                                        if (controller.model.selectedRange_Set
                                            .contains(i)) {
                                          controller.model.selectedRange_Set
                                              .remove(i);
                                        } else {
                                          controller.model.selectedRange_Set
                                              .add(i);
                                        }
                                        controller.model.recalc();
                                      });
                                    },
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    activeColor: Colors.blue,
                                    checkColor: Colors.white,
                                  ),
                                ),
                                Text(
                                  '(pt ${controller.model.selectedPoint.toInt()})',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        Expanded(
                          flex: 2,
                          child: Container(
                            color: r.color,
                            alignment: Alignment.center,
                            child: r.points == 0
                                ? const SizedBox.shrink()
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Transform.scale(
                                        scale: 0.8,
                                        child: Radio<double>(
                                          value: r.points.toDouble(),
                                          groupValue:
                                              controller.model.selectedPoint,
                                          onChanged: (value) {
                                            setState(() {
                                              controller.model.selectedPoint =
                                                  value!;
                                              controller.model.recalc();
                                            });
                                          },
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                          activeColor: Colors.blue,
                                          focusColor: Colors.black,
                                          fillColor:
                                              MaterialStateProperty.resolveWith(
                                                (states) {
                                                  if (states.contains(
                                                    MaterialState.selected,
                                                  )) {
                                                    return Colors.blue;
                                                  }
                                                  return Colors.white;
                                                },
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        r.points.toStringAsFixed(2),
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _numberGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _cornerHeader(),
            ...List.generate(_colCount, _editableHeader),
            SizedBox(width: 5),
            SizedBox(
              height: BettingGridModel.headerH - 16,
              child: Row(
                children: [
                  Container(
                    width: BettingGridModel.cellW,
                    alignment: Alignment.center,
                    color: Colors.yellow.shade600,
                    child: const Text(
                      'QTY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 4),
                  Container(
                    width: BettingGridModel.cellW,
                    alignment: Alignment.center,
                    color: Colors.pink.shade300,
                    child: const Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        ...List.generate(_rowCount, _row),
      ],
    );
  }

  Widget _row(int row) {
    return Row(
      children: [
        _editableRowHeader(row),
        ...List.generate(_colCount, (col) {
          final index = row * _colCount + col;

          if (index >= _totalNumbers) {
            return SizedBox(width: BettingGridModel.cellW);
          }

          final n = controller.model.visibleStart + index;

          return _cell(n);
        }),
        SizedBox(width: 6),

        _rowTotals(row),

        // _editableRowHeader(row),
      ],
    );
  }

  Widget _cell(int n) {
    final ctrl = controller.model._getCtrl(
      controller.model.selectedSeries,
      controller.model.selectedRange,
      n,
    );

    final focusNode = _getFocusNode(n);

    // 🔥 Handle BOTH KeyDown + KeyRepeat (for long press)
    focusNode.onKeyEvent = (node, event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
        return KeyEventResult.ignored;
      }

      final int start = controller.model.visibleStart;
      final int currentIndex = n - start;

      int newIndex = currentIndex;

      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowRight:
          newIndex++;
          debugPrint("Pressed →");
          break;

        case LogicalKeyboardKey.arrowLeft:
          newIndex--;
          debugPrint("Pressed ←");
          break;

        case LogicalKeyboardKey.arrowDown:
          newIndex += _colCount;
          debugPrint("Pressed ↓");
          break;

        case LogicalKeyboardKey.arrowUp:
          newIndex -= _colCount;
          debugPrint("Pressed ↑");
          break;

        case LogicalKeyboardKey.enter:
          newIndex += _colCount;
          debugPrint("Pressed ENTER");
          break;

        default:
          return KeyEventResult.ignored;
      }

      // 🔥 STRICT EDGE PROTECTION (NO WRAP)
      if (newIndex < 0) {
        debugPrint("At FIRST cell — cannot move back");
        debugPrint("----- NAV END -----\n");
        return KeyEventResult.handled;
      }

      if (newIndex >= _totalNumbers) {
        debugPrint("At LAST cell — cannot move forward");
        debugPrint("----- NAV END -----\n");
        return KeyEventResult.handled;
      }

      final int newNumber = start + newIndex;

      debugPrint("Moving To: $newNumber");
      debugPrint("----- NAV END -----\n");

      _cellFocusNodes[newNumber]?.requestFocus();

      return KeyEventResult.handled;
    };

    // 🔥 Clean focus listener (no stacking)
    focusNode.removeListener(_rebuildOnFocus);
    focusNode.addListener(_rebuildOnFocus);

    final bool hasValue = ctrl.text.trim().isNotEmpty;
    final bool isFocused = focusNode.hasFocus;

    final Color cellColor = controller.model.isFPChecked && hasValue
        ? Colors.yellow.shade300
        : isFocused
        ? Colors.green.shade200
        : Colors.white;

    return SizedBox(
      width: BettingGridModel.cellW,
      height: BettingGridModel.cellH + 4,
      child: Column(
        children: [
          SizedBox(
            height: 18,
            child: Center(
              child: Text(
                n.toString().padLeft(4, '0'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: TextField(
                focusNode: focusNode,
                controller: ctrl,
                enabled: !controller.model.block,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: cellColor,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: controller.model.isFPChecked && hasValue
                          ? Colors.orange.shade600
                          : Colors.green.shade400,
                      width: 0.6,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (ctrl.text != value) return;

                  setState(() {
                    controller.model.onCellChanged(
                      n,
                      value,
                      context,
                      controller.model.isFPChecked,
                    );
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _rebuildOnFocus() {
    if (mounted) setState(() {});
  }

  Widget _cornerHeader() {
    return SizedBox(
      width: BettingGridModel.cellW,
      height: BettingGridModel.headerH,
      child: const Center(
        child: Text(
          'Block',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _editableHeader(int col) {
    controller.model.headerCtrls.putIfAbsent(
      col,
      () => TextEditingController(),
    );

    _headerFocusNodes.putIfAbsent(col, () {
      final node = FocusNode();

      node.onKeyEvent = (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          int? targetCol;

          // RIGHT
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            targetCol = col + 1;
          }
          //  LEFT
          else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            targetCol = col - 1;
          }
          //  DOWN
          else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            targetCol = col + 1;
          }
          // UP
          else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            targetCol = col - 1;
          }

          if (targetCol != null && _headerFocusNodes.containsKey(targetCol)) {
            _headerFocusNodes[targetCol]!.requestFocus();
            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      };

      node.addListener(() => setState(() {}));
      return node;
    });

    _headerHoverState.putIfAbsent(col, () => false);

    final focusNode = _headerFocusNodes[col]!;

    return MouseRegion(
      onEnter: (_) => setState(() => _headerHoverState[col] = true),
      onExit: (_) => setState(() => _headerHoverState[col] = false),
      child: SizedBox(
        width: BettingGridModel.cellW,
        height: BettingGridModel.headerH - 16,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: focusNode.hasFocus
              ? Colors.green.shade200
              : const Color.fromRGBO(52, 73, 95, 1),
          child: TextField(
            focusNode: focusNode,
            controller: controller.model.headerCtrls[col],
            enabled: !controller.model.block,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: focusNode.hasFocus ? Colors.black : Colors.white,
            ),
            decoration: InputDecoration(
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              suffixIcon: Container(
                width: 2,
                color: Colors.white.withOpacity(0.6),
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 1,
                maxWidth: 1,
              ),
            ),
            onChanged: (v) =>
                controller.model.applyColumnValue(col, v, context),
          ),
        ),
      ),
    );
  }

  Widget _editableRowHeader(int row) {
    controller.model.rowCtrls.putIfAbsent(row, () => TextEditingController());

    _rowFocusNodes.putIfAbsent(row, () {
      final node = FocusNode();

      node.onKeyEvent = (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          int? targetRow;

          // ➡️ RIGHT
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            targetRow = row + 1;
          }
          // ⬅️ LEFT
          else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            targetRow = row - 1;
          }
          // ⬇️ DOWN
          else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            targetRow = row + 1;
          }
          // ⬆️ UP
          else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            targetRow = row - 1;
          }

          if (targetRow != null && _rowFocusNodes.containsKey(targetRow)) {
            _rowFocusNodes[targetRow]!.requestFocus();
            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      };

      node.addListener(() => setState(() {}));
      return node;
    });

    _rowHoverState.putIfAbsent(row, () => false);

    final focusNode = _rowFocusNodes[row]!;

    return MouseRegion(
      onEnter: (_) => setState(() => _rowHoverState[row] = true),
      onExit: (_) => setState(() => _rowHoverState[row] = false),
      child: Column(
        children: [
          const SizedBox(height: 16),
          SizedBox(
            width: BettingGridModel.cellW,
            height: BettingGridModel.cellH - 16,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: focusNode.hasFocus
                    ? Colors.green.shade200
                    : const Color.fromRGBO(52, 73, 95, 1),
                border: Border.all(
                  color: Colors.black.withOpacity(0.35),
                  width: 0.4,
                ),
              ),
              child: TextField(
                focusNode: focusNode,
                controller: controller.model.rowCtrls[row],
                enabled: !controller.model.block,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: focusNode.hasFocus ? Colors.black : Colors.white,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
                onChanged: (v) =>
                    controller.model.applyRowValue(row, v, context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== RIGHT TOTALS =====================

  Widget _rowTotals(int row) {
    final int slotMultiplier = slots.isEmpty ? 1 : slots.length;
    final result = controller._calculateTotals(row: row);

    // print(result);

    final int finalQty = (result['qty'] as int) * slotMultiplier;

    final double finalAmount = (result['amount'] as double) * slotMultiplier;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: BettingGridModel.cellH - 16,
        child: Row(
          children: [
            Container(
              width: BettingGridModel.cellW,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF34495F),
                border: Border.all(
                  color: Colors.black.withOpacity(0.35),
                  width: 0.4,
                ),
              ),
              child: Text(
                finalQty.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: BettingGridModel.cellW,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE8CE8A),
                border: Border.all(
                  color: Colors.black.withOpacity(0.35),
                  width: 0.4,
                ),
              ),
              child: Text(
                finalAmount.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomSummary() {
    final result = controller._calculateTotals();

    final int slotMultiplier = slots.isEmpty ? 1 : slots.length;

    ///  _summaryItem('SLots', '${slots.length}'), based on this if slots.isepty tehn show slot and current and not then slots and there value

    final int baseQty = (result['qty'] ?? 0) as int;
    final double baseAmount = (result['amount'] ?? 0.0) as double;

    final int totalQty = baseQty * slotMultiplier;
    final double totalAmount = baseAmount * slotMultiplier;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            "assets/banner_image_1.png",
            fit: BoxFit.fill,
            height: 85,
            width: 900,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _summaryItem('Total qty', totalQty.toString()),
              SizedBox(width: 2),

              _summaryItem(
                'Total Amount',
                '₹${totalAmount.toStringAsFixed(0)}',
              ),
              SizedBox(width: 2),
              _summaryItem(
                slots.isEmpty ? 'Slot' : 'Slots',
                slots.isEmpty ? 'Current' : '${slots.length}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _bottomSummary() {
  //   final selections = controller.model.collectAllNumbersForPrint();
  //   final int slotMultiplier = slots.isEmpty ? 1 : slots.length;
  //
  //   final List<int> multipliers = [1, 1, 2, 3, 5, 5, 10, 20, 25, 25];
  //
  //   int totalQty = 0;
  //   double totalAmount = 0.0;
  //
  //   // ================= LOW MODE =================
  //   if (!controller.model.high) {
  //     for (final entry in selections.entries) {
  //       final int qty = entry.value;
  //
  //       totalQty += qty;
  //       totalAmount += qty * controller.model.selectedPoint;
  //     }
  //   }
  //
  //   // ================= HIGH MODE =================
  //   else {
  //     for (final entry in selections.entries) {
  //       final int number = entry.key;
  //       final int qty = entry.value;
  //
  //       // ✅ Correct series logic (0000–0999, 1000–1999...)
  //       final int series = number ~/ 1000;
  //
  //       int multiplier = 1;
  //       if (series >= 0 && series < multipliers.length) {
  //         multiplier = multipliers[series];
  //       }
  //
  //       // 🔥 Apply multiplier to qty
  //       final int highQty = qty * multiplier;
  //
  //       totalQty += highQty;
  //
  //       // 🔥 Amount = qty × point × multiplier
  //       totalAmount += qty *
  //           controller.model.selectedPoint *
  //           multiplier;
  //     }
  //   }
  //
  //   // 🔥 Apply slot multiplier at end
  //   totalQty *= slotMultiplier;
  //   totalAmount *= slotMultiplier;
  //
  //   return SizedBox(
  //     height: 60,
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.end,
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         Expanded(
  //           child: Text(
  //                 () {
  //               final selections =
  //               controller.model.collectAllNumbersForPrint();
  //
  //               if (selections.isEmpty) {
  //                 return 'No numbers selected';
  //               }
  //
  //               const int limit = 99;
  //
  //               final entries = selections.entries.toList()
  //                 ..sort((a, b) => a.key.compareTo(b.key));
  //
  //               final formatted = entries.map((entry) {
  //                 final number = entry.key.toString().padLeft(4, '0');
  //                 final qty = entry.value;
  //                 return '$number($qty)';
  //               }).toList();
  //
  //               final visible = formatted.take(limit).join(', ');
  //               final remaining = formatted.length - limit;
  //
  //               if (formatted.length > limit) {
  //                 return 'Selected numbers: $visible +$remaining more';
  //               }
  //
  //               return 'Selected numbers: $visible';
  //             }(),
  //             style: const TextStyle(
  //               fontSize: 8,
  //               fontWeight: FontWeight.w600,
  //               color: Color(0xFF222222),
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 20),
  //
  //         _summaryItem('Total QTY', totalQty.toString()),
  //
  //         const SizedBox(width: 24),
  //
  //         _summaryItem(
  //             'Total Amount', '₹${totalAmount.toStringAsFixed(2)}'),
  //
  //         const SizedBox(width: 20),
  //       ],
  //     ),
  //   );
  // }

  Widget _summaryItem(String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 16, // better desktop size
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 150,
          // slightly wider for better alignment
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Color(0xFFCCCCCC), width: 1),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16, // clear desktop number
              fontWeight: FontWeight.w700,
              color: Color(0xFF222222),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomButtons(String userId) {
    const double btnHeight = 30;
    const double btnWidth = 180;

    final model = controller.model;
    final barcodeCtrl = model.barcodeController;
    final barcodeFocus = model.barcodeFocus;
    var debounce = model._debounce;

    return SizedBox(
      height: btnHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          /// ================= PRINT =================
          ModernBtn(
            text: 'Print',
            bgColor: const Color(0xFF311B92),
            width: btnWidth,
            height: btnHeight,
            onTap: () async {
              print("Ticket Print");

              final result = await controller.handlePrint(
                context,
                widget.slot,
                slots,
                widget.id,
              );

              if (result["success"] == true) {
                showInfoDialog(
                  context: context,
                  title: "Success",
                  subtitle: "Ticket printed successfully.",
                );
                return;
              }

              final failedAt = result["failedAt"];

              switch (failedAt) {
                case "game_not_started":
                  showInfoDialog(
                    context: context,
                    title: "Game Not Started",
                    subtitle: "Game will start at 09:45 AM. Please wait.",
                  );
                  break;

                case "game_closed":
                  showInfoDialog(
                    context: context,
                    title: "Game Closed",
                    subtitle:
                        "Today's game time is over. Please come tomorrow.",
                  );
                  break;

                case "slot_missing":
                  showInfoDialog(
                    context: context,
                    title: "Slot Required",
                    subtitle: "Please select a draw time slot.",
                  );
                  break;

                case "empty_selection":
                  showInfoDialog(
                    context: context,
                    title: "No Quantity",
                    subtitle: "Enter quantity for at least one number.",
                  );
                  break;

                case "no_selection":
                  showInfoDialog(
                    context: context,
                    title: "No Numbers",
                    subtitle: "No valid numbers selected.",
                  );
                  break;

                case "server_error":
                  showInfoDialog(
                    context: context,
                    title: "Server Error",
                    subtitle: "Server error occurred. Please try again.",
                  );
                  break;

                case "api_rejected":
                  showInfoDialog(
                    context: context,
                    title: "Request Failed",
                    subtitle: result["message"],
                  );
                  break;

                case "exception":
                  showInfoDialog(
                    context: context,
                    title: "Unexpected Error",
                    subtitle: "Something went wrong. Please try again.",
                  );
                  break;

                default:
                  showInfoDialog(
                    context: context,
                    title: "Error",
                    subtitle: "Unknown error occurred.",
                  );
              }
            },
          ),

          const SizedBox(width: 6),

          /// ================= CLEAR =================
          ModernBtn(
            text: 'Clear',
            bgColor: Colors.pink,
            width: btnWidth,
            height: btnHeight,
            onTap: _isClearing
                ? () {}
                : () async {
                    setState(() => _isClearing = true);

                    try {
                      setState(() {
                        slots = [];
                        model.clear(slots);
                        barcodeCtrl.clear();
                      });
                    } catch (e) {
                      debugPrint("Clear Error: $e");
                    } finally {
                      if (mounted) {
                        setState(() => _isClearing = false);
                      }
                    }
                  },
          ),

          const SizedBox(width: 6),

          /// ================= BARCODE FIELD =================
          Expanded(
            child: SizedBox(
              height: btnHeight,
              child: TextField(
                controller: barcodeCtrl,
                focusNode: barcodeFocus,
                autofocus: true,
                cursorColor: Colors.white,

                // 🔥 Auto detect scanner + manual typing
                onChanged: (value) {
                  if (debounce?.isActive ?? false) {
                    debounce!.cancel();
                  }

                  debounce = Timer(const Duration(seconds: 1), () {
                    if (value.trim().isNotEmpty) {
                      _handleClaim();
                    }
                  });
                },

                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: "Enter / Scan Barcode",
                  filled: true,
                  fillColor: const Color.fromRGBO(52, 73, 95, 1),
                  hintStyle: const TextStyle(color: Colors.white70),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Colors.black, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                      color: Colors.black,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          /// ================= CLAIM =================
          ModernBtn(
            text: 'Claim',
            bgColor: Colors.orange,
            width: btnWidth,
            height: btnHeight,
            onTap: _handleClaim,
          ),

          const SizedBox(width: 4),

          /// ================= TRANSACTION =================
          ModernBtn(
            text: 'Transaction',
            bgColor: Colors.deepPurple,
            width: btnWidth,
            height: btnHeight,
            onTap: () => openTransactionDialog(context, userId, widget.slot),
          ),

          const SizedBox(width: 4),

          /// ================= ADVANCED DRAW =================
          ModernBtn(
            text: 'Advanced Draw',
            bgColor: Colors.lightGreen,
            width: btnWidth,
            height: btnHeight,
            onTap: () async {
              final selectedSlots = await showSlotDialog(
                context,
                selectedTimes: slots,
              );

              if (!mounted) return;

              setState(() {
                slots = selectedSlots ?? [];
              });
            },
          ),
        ],
      ),
    );
  } //

  Future<void> _handleClaim() async {
    if (isClaiming) return;

    final id = controller.model.barcodeController.text.trim();
    controller.model.barcodeController.clear();
    if (id.isEmpty) {
      showInfoDialog(
        context: context,
        title: "Invalid Ticket",
        subtitle: "Please enter or scan a ticket number.",
      );
      return;
    }

    setState(() => isClaiming = true);

    try {
      final result = await homeController.claim(id: id);

      if (!mounted) return;

      final bool status = result["status"] == true;
      final String message = result["message"];
      final int winner = result["winner"] ?? 0;
      final int wallet = int.tryParse(result["walate"].toString()) ?? 0;

      if (!status) {
        showInfoDialog(
          context: context,
          title: "Claim Failed",
          subtitle: message,
        );
        return;
      }

      if (winner > 0) {
        await _showWinnerDialog(id, message, winner, wallet);
        controller.model.barcodeController.clear();
        return;
      }

      showInfoDialog(
        context: context,
        title: "Already Claimed",
        subtitle: message,
      );
    } catch (e) {
      if (mounted) {
        showInfoDialog(
          context: context,
          title: "Something went wrong",
          subtitle: "Please try again.",
        );
      }
    } finally {
      if (mounted) {
        setState(() => isClaiming = false);
      }
    }
  }

  Future<void> _showWinnerDialog(
    String id,
    String message,
    int winner,
    int wallet,
  ) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: 420,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF141428), Color(0xFF1A1A2E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAB676).withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEAB676).withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// ===== HEADER =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFD4A054),
                      Color(0xFFEAB676),
                      Color(0xFFD4A054),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                    SizedBox(height: 8),
                    Text(
                      "WINNING TICKET",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ],
                ),
              ),

              /// ===== BODY =====
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      "Ticket #${id.toUpperCase()}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// ===== PRIZE BOX =====
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D0D1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFEAB676).withOpacity(0.35),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "PRIZE AMOUNT",
                            style: TextStyle(
                              color: const Color(0xFFEAB676).withOpacity(0.8),
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "₹ $winner",
                            style: const TextStyle(
                              color: Color(0xFFEAB676),
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// ===== UPDATED BALANCE =====
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Updated Balance",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "₹ $wallet",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// ===== CLOSE BUTTON =====
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEAB676),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "CLOSE",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _modernBtn(
  //   String text,
  //   Color bgColor,
  //   double width,
  //   double height,
  //   VoidCallback fn,
  // ) {
  //   return StatefulBuilder(
  //     builder: (context, setState) {
  //       bool isPressed = false;
  //
  //       Color darken(Color c, double amt) => Color.fromARGB(
  //         c.alpha,
  //         (c.red * (1 - amt)).round(),
  //         (c.green * (1 - amt)).round(),
  //         (c.blue * (1 - amt)).round(),
  //       );
  //
  //       final deep = darken(bgColor, 0.2);
  //
  //       return GestureDetector(
  //         onTapDown: (_) => setState(() => isPressed = true),
  //         onTapUp: (_) {
  //           setState(() => isPressed = false);
  //           fn();
  //         },
  //         onTapCancel: () => setState(() => isPressed = false),
  //         child: AnimatedContainer(
  //           duration: const Duration(milliseconds: 120),
  //           width: width,
  //           height: height,
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(8),
  //             gradient: LinearGradient(
  //               begin: Alignment.topLeft,
  //               end: Alignment.bottomRight,
  //               colors: [deep, deep],
  //             ),
  //           ),
  //           child: Center(
  //             child: Text(
  //               text,
  //               style: const TextStyle(
  //                 color: Colors.white,
  //                 fontWeight: FontWeight.w700,
  //                 fontSize: 14,
  //                 letterSpacing: 0.8,
  //               ),
  //             ),
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
  //
  // void _showPrintLoader(
  //   BuildContext context,
  //   BettingGridController controller,
  //   String slot,
  // ) async {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (_) {
  //       return Dialog(
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
  //         elevation: 12,
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               const SizedBox(
  //                 height: 38,
  //                 width: 38,
  //                 child: CircularProgressIndicator(strokeWidth: 3),
  //               ),
  //               const SizedBox(height: 18),
  //               const Text(
  //                 "Saving bet details…",
  //                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  //               ),
  //               const SizedBox(height: 6),
  //               const Text(
  //                 "Please wait while we prepare your print",
  //                 textAlign: TextAlign.center,
  //                 style: TextStyle(fontSize: 13, color: Colors.grey),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  //
  //   /// 🔹 Do the actual print work
  //   await controller.handlePrint(context, slot, slots, widget.id);
  //
  //   /// 🔹 Close loader after work is done
  //   if (context.mounted) {
  //     Navigator.of(context).pop();
  //   }
  // }
}

class ModernBtn extends StatefulWidget {
  final String text;
  final Color textColor;
  final Color bgColor;
  final double width;
  final double height;
  final VoidCallback onTap;

  ModernBtn({
    super.key,
    this.textColor = Colors.white,
    required this.text,
    required this.bgColor,
    required this.width,
    required this.height,
    required this.onTap,
  });

  @override
  State<ModernBtn> createState() => _ModernBtnState();
}

class _ModernBtnState extends State<ModernBtn> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) {
        setState(() => isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => isPressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 300),
        scale: isPressed ? 0.8 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4), //
            color: widget.bgColor,
            boxShadow: isPressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                    ),
                  ],
          ),
          child: Stack(
            children: [
              // Main Content
              Center(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.6,
                  ),
                ),
              ),

              // Grey overlay when pressed
              if (isPressed)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.grey.withOpacity(0.4),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
