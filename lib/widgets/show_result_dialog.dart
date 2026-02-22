import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:shreelott/service/ticket_print_service.dart';

import '../consts/api_consts.dart';
import '../consts/app_colors.dart';
import '../controller/home_controller.dart' hide ApiConstants;

class ResultDialog extends StatefulWidget {
  const ResultDialog({super.key});

  @override
  State<ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<ResultDialog> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay(
    hour: (DateTime.now().hour < 10)
        ? 10
        : (DateTime.now().hour > 21 ||
              (DateTime.now().hour == 21 &&
                  (DateTime.now().minute ~/ 15) * 15 > 30))
        ? 21
        : DateTime.now().hour,
    minute: (DateTime.now().hour < 10)
        ? 0
        : (DateTime.now().hour > 21 ||
              (DateTime.now().hour == 21 &&
                  (DateTime.now().minute ~/ 15) * 15 > 30))
        ? 30
        : (DateTime.now().minute ~/ 15) * 15,
  );
  bool loading = false;

  List<ResultItem> results = [];

  String baseUrl = "${ApiConstants.baseUrl}/get-result";

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  // ============================================================
  // API CALL
  // ============================================================
  Future<void> _loadResult() async {
    if (!mounted) return;

    setState(() => loading = true);

    try {
      final String date =
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";

      final String time =
          "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}";

      final Uri uri = Uri.parse("$baseUrl?date=$date&draw_time=$time");

      final String token = await ApiClient.getToken();

      final http.Response res = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final Map<String, dynamic> body = jsonDecode(res.body);

        final List<dynamic> list = body["result"] is List ? body["result"] : [];

        results = list.map<ResultItem>((e) {
          return ResultItem(
            type: int.tryParse(e["type"].toString()) ?? 0,
            subType: int.tryParse(e["sub_type"].toString()) ?? 0,
            winningNumber: e["winning_number"]?.toString() ?? "",
          );
        }).toList();
      } else {
        results = [];
      }
    } catch (_) {
      results = [];
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            child: Container(color: AppColors.overlayBlackTransparent(0.35)),
          ),

          // Main card
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.95,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  // Premium radial gradient
                  // gradient: RadialGradient(
                  //   center: const Alignment(0.3, -0.3),
                  //   radius: 1.2,
                  //   colors: [
                  //     AppColors.primaryMedium.withOpacity(0.95),
                  //     AppColors.primaryDarker,
                  //   ],
                  //   stops: const [0.0, 1.0],
                  // ),

                  // Layered shadows
                  boxShadow: AppColors.premiumCardShadow,

                  // Gold border
                  border: Border.all(
                    color: AppColors.accentGold.withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    // Close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                          splashRadius: 24,
                        ),
                      ],
                    ),

                    // Filters (Date & Time)
                    _filters(),

                    const SizedBox(height: 12),

                    // Content (Results grid)
                    Expanded(child: _content()),

                    // Print button
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentYellow,
                          foregroundColor: AppColors.textDark,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          elevation: 8,
                          shadowColor: AppColors.accentYellow.withOpacity(0.5),
                        ),
                        onPressed: () {
                          _showPrintOptions(results);
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.print),
                            SizedBox(width: 8),
                            Text(
                              "Print Result",
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
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
  }

  // ============================================================
  // FILTERS
  // ============================================================
  Widget _filters() {
    return Row(
      children: [
        Expanded(child: _datePicker()),
        const SizedBox(width: 16),
        Expanded(child: _timePicker()),
      ],
    );
  }

  Widget _datePicker() {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );

        if (picked != null) {
          setState(() => selectedDate = picked);
          _loadResult();
        }
      },
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              "${selectedDate.day.toString().padLeft(2, '0')}-"
              "${selectedDate.month.toString().padLeft(2, '0')}-"
              "${selectedDate.year}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timePicker() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TimeOfDay>(
          dropdownColor: const Color(0xFF1565C0),
          value: selectedTime,
          isExpanded: true,
          icon: const Icon(Icons.access_time, color: Colors.white),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          items: _timeSlots().map((t) {
            return DropdownMenuItem(
              value: t,
              child: Text(
                DateFormat(
                  'hh:mm a',
                ).format(DateTime(0, 0, 0, t.hour, t.minute)),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => selectedTime = v);
            _loadResult();
          },
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================
  Widget _content() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold),
        ),
      );
    }

    if (results.isEmpty) {
      return const Center(
        child: Text(
          "No result available",
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        border: TableBorder(
          horizontalInside: BorderSide(color: Colors.grey.shade300, width: 1),
          verticalInside: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        columnWidths: const {
          0: FixedColumnWidth(100),
          1: FixedColumnWidth(100),
          2: FixedColumnWidth(100),
          3: FixedColumnWidth(100),
          4: FixedColumnWidth(100),
          5: FixedColumnWidth(100),
          6: FixedColumnWidth(100),
          7: FixedColumnWidth(100),
          8: FixedColumnWidth(100),
          9: FixedColumnWidth(100),
        },
        children: List.generate(
          10, // 10 rows
          (rowIndex) {
            return TableRow(
              children: List.generate(
                10, // 10 columns
                (colIndex) {
                  final index = rowIndex * 10 + colIndex;

                  final ResultItem? item = index < results.length
                      ? results[index]
                      : null;

                  return Container(
                    height: 48,
                    alignment: Alignment.center,
                    color: rowIndex.isEven ? Colors.white : Colors.grey.shade50,
                    child: Text(
                      item == null
                          ? ""
                          : "${item.type}${item.subType}${item.winningNumber}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _numberColor(colIndex),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// Color for each column in the grid
  Color _numberColor(int col) {
    const colors = [
      Color(0xFFFF385C), // Red
      AppColors.accentGreen, // Green
      Color(0xFF2196F3), // Blue
      Colors.black, // Yellow
      Color(0xFF9C27B0), // Purple
      AppColors.accentGold, // Gold
      Color(0xFFFF6F00), // Deep Orange
      Color(0xFF00BCD4), // Cyan
      Color(0xFF4CAF50), // Light Green
      Color(0xFFE91E63), // Pink
    ];
    return colors[col];
  }

  /// Generate time slots from 10 AM to 9:30 PM (15 min interval)
  List<TimeOfDay> _timeSlots() {
    final slots = <TimeOfDay>[];

    for (int h = 10; h <= 21; h++) {
      for (int m = 0; m < 60; m += 15) {
        if (h == 21 && m > 30) break; // stop at 9:30 PM
        slots.add(TimeOfDay(hour: h, minute: m));
      }
    }

    return slots;
  }

  /// Show print format options
  void _showPrintOptions(List<ResultItem> resultItems) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.primaryDarker,
        title: const Text(
          "Select Print Format",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await TicketPrintService.printResult(
                context,
                resultItems,
                PdfPageFormat.a4,
                DateFormat('dd MMM yyyy').format(selectedDate),
                DateFormat('hh:mm a').format(
                  DateTime(0, 0, 0, selectedTime.hour, selectedTime.minute),
                ),
              );
            },
            child: const Text(
              "A4 Page",
              style: TextStyle(
                color: AppColors.accentGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await TicketPrintService.printResult(
                context,
                resultItems,
                PdfPageFormat.roll80,
                DateFormat('dd MMM yyyy').format(selectedDate),
                DateFormat('hh:mm a').format(
                  DateTime(0, 0, 0, selectedTime.hour, selectedTime.minute),
                ),
              );
            },
            child: const Text(
              "Thermal",
              style: TextStyle(
                color: AppColors.accentYellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Model for result items
class ResultItem {
  final int type;
  final int subType;
  final String winningNumber;

  ResultItem({
    required this.type,
    required this.subType,
    required this.winningNumber,
  });
}
