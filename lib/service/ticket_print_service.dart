import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/shop_report_model.dart';
import '../widgets/show_result_dialog.dart';

// ================= CONSTANTS =================
class PdfStyleConstants {
  // Font sizes
  static const double brandFontSize = 6;
  static const double legalTextSize = 7;
  static const double tableDataSize = 9;
  static const double tableHeaderSize = 6;
  static const double reportTitleSize = 12;
  static const double sectionHeaderSize = 8;
  static const double barcodeTextSize = 7;
  static const double footerTextSize = 7;
  static const double accountTitleSize = 10;
  static const double accountSubtitleSize = 9;
  static const double accountDataSize = 8;

  // Colors
  static const String dividerColorLight = 'grey300';
  static const String dividerColorDark = 'grey400';

  // Page dimensions
  static const double thermalRollWidth = 2.5; // inches
  static const double pageMarginDefault = 10;
  static const double pageMarginCompact = 6;
  static const double pageMarginBottom = 12;
}

class PdfLayoutConstants {
  // Spacing
  static const double spacingXSmall = 2;
  static const double spacingSmall = 3;
  static const double spacingMedium = 4;
  static const double spacingLarge = 6;
  static const double spacingXLarge = 8;
  static const double spacingXXLarge = 12;

  // Divider heights
  static const double dividerHeight = 0.6;

  // Grid layout
  static const int gridColumnsTicket = 3;
  static const int gridColumnsResultStandard = 10;
  static const int gridColumnsResultRoll80 = 4;

  // Barcode dimensions
  static const double barcodeWidth = 150;
  static const double barcodeHeight = 55;
}

// ================= ENUMS & MODELS =================
enum DividerType {
  light, // grey300 - used in tickets
  dark, // grey400 - used in reports
}

class PointSummaryRow {
  final String date;
  final double sale;
  final double commission;
  final double winning;
  final double net;

  PointSummaryRow({
    required this.date,
    required this.sale,
    required this.commission,
    required this.winning,
    required this.net,
  });
}

// ================= MAIN SERVICE CLASS =================
class TicketPrintService {
  // ================= REUSABLE PDF BUILDERS =================

  /// Build a divider line with configurable style and padding
  static pw.Widget buildDivider({
    DividerType type = DividerType.light,
    double verticalPadding = 0,
    double height = PdfLayoutConstants.dividerHeight,
  }) {
    final color = type == DividerType.light
        ? PdfColors.grey300
        : PdfColors.grey400;

    final divider = pw.Container(height: height, color: color);

    if (verticalPadding > 0) {
      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(vertical: verticalPadding),
        child: divider,
      );
    }
    return divider;
  }

  /// Build a key-value row with customizable styling
  static pw.Widget buildKeyValueRow(
    String key,
    String value, {
    double keyFontSize = PdfStyleConstants.legalTextSize,
    double valueFontSize = PdfStyleConstants.legalTextSize,
    double verticalPadding = PdfLayoutConstants.spacingXSmall,
    bool valueBold = true,
  }) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: verticalPadding),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(key, style: pw.TextStyle(fontSize: keyFontSize)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: valueFontSize,
              fontWeight: valueBold ? pw.FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a table cell with flexible styling
  static pw.Widget buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    double fontSize = PdfStyleConstants.tableHeaderSize,
  }) {
    return pw.Expanded(
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  /// Build centered text with optional styling
  static pw.Widget buildCenteredText(
    String text, {
    double fontSize = PdfStyleConstants.barcodeTextSize,
    bool bold = false,
  }) {
    return pw.Center(
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : null,
        ),
      ),
    );
  }

  /// Build a sized box (vertical spacer)
  static pw.Widget buildVerticalSpace(double height) {
    return pw.SizedBox(height: height);
  }

  // ================= UTILITY METHODS =================

  /// Safely format numeric values to fixed decimal places
  static String formatNumber(dynamic value, int decimals) {
    if (value == null) return (0).toStringAsFixed(decimals);

    if (value is num) {
      return value.toStringAsFixed(decimals);
    }

    final parsed = num.tryParse(value.toString());
    return (parsed ?? 0).toStringAsFixed(decimals);
  }

  /// Safely access map values with fallback
  static String safeGet(
    Map<String, dynamic> data,
    String key, [
    String fallback = "0",
  ]) {
    return (data[key] ?? fallback).toString();
  }

  // ================= PRINTER MANAGEMENT =================

  static Future<Printer?> _getPrinter(BuildContext context) async {
    final box = Hive.isBoxOpen('printerBox')
        ? Hive.box('printerBox')
        : await Hive.openBox('printerBox');

    Printer? printer;
    final savedName = box.get('printer_name');

    if (savedName != null) {
      final printers = await Printing.listPrinters();
      printer = await _selectOrFallbackPrinter(printers, savedName);
    }

    printer ??= await Printing.pickPrinter(context: context);

    if (printer != null) {
      await box.put('printer_name', printer.name);
    }

    return printer;
  }

  /// Select a printer by name or fallback to first available
  static Future<Printer?> _selectOrFallbackPrinter(
    List<Printer> printers,
    String savedName,
  ) async {
    if (printers.isEmpty) return null;

    return printers.firstWhere(
      (p) => p.name == savedName,
      orElse: () => printers.first,
    );
  }

  // ================= TICKET PRINTING =================

  static Future<void> printTicket({
    required BuildContext context,
    required Map<String, int> selections,
    required List<String> ticketIds,
    required List<String> ticketTimes,
    required List<int> ticketsAmounts,
    required String date,
    required int totalQty,
    required String userId,
  }) async {
    final printer = await _getPrinter(context);
    if (printer == null) return;

    final pdf = pw.Document();

    const double rowHeight = 14;
    const double headerHeight = 140;
    const double footerHeight = 120;

    final int rowsPerTicket = selections.length;

    final double singleTicketHeight =
        headerHeight + (rowsPerTicket * rowHeight) + footerHeight + 100;

    // ✅ Each ticket = its own page = auto cut
    for (int i = 0; i < ticketIds.length; i++) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            2.5 * PdfPageFormat.inch,
            PdfPageFormat.a4.height, // ✅ exact height per ticket
          ),
          margin: pw.EdgeInsets.fromLTRB(
            PdfStyleConstants.pageMarginDefault,
            PdfStyleConstants.pageMarginDefault,
            PdfStyleConstants.pageMarginDefault,
            PdfStyleConstants.pageMarginBottom,
          ),
          build: (context) => _buildTicketContent(
            selections: selections,
            ticketId: "SL${ticketIds[i]}",
            date: date,
            time: i < ticketTimes.length
                ? ticketTimes[i]
                : ticketTimes.first,
            totalQty: totalQty,
            ticketAmount: i < ticketsAmounts.length
                ? ticketsAmounts[i]
                : ticketsAmounts.first,
            userId: userId,
          ),
        ),
      );
    }

    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (_) async => pdf.save(),
    );
  }

  static pw.Widget _buildTicketContent({
      required Map<String, int> selections,
      required String ticketId,
      required String date,
      required String time,
      required int totalQty,
      required int ticketAmount,
      required String userId,
    }) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // BRAND
          pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Shree Lott',
                style: pw.TextStyle(
                  fontSize: PdfStyleConstants.brandFontSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'FOR AMUSEMENT ONLY',
                style: pw.TextStyle(fontSize: PdfStyleConstants.brandFontSize),
              ),
            ],
          ),

          // METADATA
          buildKeyValueRow(
            'Terminal ID',
            userId,
            keyFontSize: PdfStyleConstants.legalTextSize,
          ),
          buildKeyValueRow(
            'Draw Date',
            date,
            keyFontSize: PdfStyleConstants.legalTextSize,
          ),
          buildKeyValueRow(
            'Time',
            "${(int.parse(time.split(':')[0]) % 12 == 0 ? 12 : int.parse(time.split(':')[0]) % 12)}:${time.split(':')[1]} ${int.parse(time.split(':')[0]) >= 12 ? 'PM' : 'AM'}",
            keyFontSize: PdfStyleConstants.legalTextSize,
          ),
          buildKeyValueRow(
            'Ticket ID',
            ticketId,
            keyFontSize: PdfStyleConstants.legalTextSize,
          ),

          buildDivider(
            type: DividerType.light,
            verticalPadding: PdfLayoutConstants.spacingSmall,
          ),

          // TABLE HEADER


          buildVerticalSpace(PdfLayoutConstants.spacingMedium),

          // TABLE BODY
          ..._buildTicketRows(selections),

          buildDivider(
            type: DividerType.light,
            verticalPadding: PdfLayoutConstants.spacingSmall,
          ),

          // SUMMARY
          buildKeyValueRow(
            'Points',
            ticketAmount.toString(),
            keyFontSize: PdfStyleConstants.legalTextSize,
            valueFontSize: PdfStyleConstants.legalTextSize,
            verticalPadding: PdfLayoutConstants.spacingSmall,
          ),
          buildKeyValueRow(
            'Total Qty',
            totalQty.toString(),
            keyFontSize: PdfStyleConstants.legalTextSize,
            valueFontSize: PdfStyleConstants.legalTextSize,
            verticalPadding: PdfLayoutConstants.spacingSmall,
          ),

          buildVerticalSpace(PdfLayoutConstants.spacingXSmall),

          // BARCODE
          pw.Center(
            child: pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: ticketId,
              width: PdfLayoutConstants.barcodeWidth,
              height: PdfLayoutConstants.barcodeHeight,
            ),
          ),

          buildVerticalSpace(PdfLayoutConstants.spacingMedium),

          buildCenteredText(
            ticketId,
            fontSize: PdfStyleConstants.barcodeTextSize,
          ),
        ],
      );
    }

    /// Build ticket rows in 3-column grid layout
  static List<pw.Widget> _buildTicketRows(
      Map<String, int> selections,
      ) {
    final entries = selections.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    const int columns = 3;
    const int blockWidth = 9; // perfect fit for "0000 99"

    final List<pw.Widget> widgets = [];

    final textStyle =
    pw.TextStyle(
      fontSize: 8,
      font: pw.Font.courier(), // important for alignment
    );

    final String horizontalBorder =
        "-" * ((blockWidth * columns) + (columns + 1));

    // TOP BORDER
    widgets.add(pw.Text(horizontalBorder, style: textStyle));

    // HEADER
    final headerCells = List.generate(
      columns,
          (_) => "Num  Qty".padRight(blockWidth),
    );

    widgets.add(
      pw.Text(
        "|${headerCells.join("|")}|",
        style: textStyle.copyWith(fontWeight: pw.FontWeight.bold),
      ),
    );

    widgets.add(pw.Text(horizontalBorder, style: textStyle));

    // DATA ROWS
    for (int i = 0; i < entries.length; i += columns) {
      final List<String> rowCells = [];

      for (int c = 0; c < columns; c++) {
        if (i + c < entries.length) {
          final entry = entries[i + c];

          final cell =
              "${entry.key.padLeft(4, '0')}  ${entry.value.toString().padLeft(2)}";

          rowCells.add(cell.padRight(blockWidth));
        } else {
          rowCells.add("".padRight(blockWidth));
        }
      }

      widgets.add(
        pw.Text(
          "|${rowCells.join("|")}|",
          style: textStyle,
        ),
      );
    }

    // BOTTOM BORDER
    widgets.add(pw.Text(horizontalBorder, style: textStyle));

    return widgets;
  }





  static Future<void> printPointSummaryReport({
    required BuildContext context,
    required String startDate,
    required String endDate,
    required String rptDateTime,
    required String loginId,
    required String name,
    required String userName,
    required List<ShopReportRow> rows,
    required double totalSale,
    required double totalCommission,
    required double totalWinning,
    required double totalNet,
  }) async {
    final printer = await _getPrinter(context);
    if (printer == null) return;

    final pdf = _buildPointSummaryPdf(
      startDate: startDate,
      endDate: endDate,
      rptDateTime: rptDateTime,
      loginId: loginId,
      name: name,
      userName: userName,
      rows: rows,
      totalSale: totalSale,
      totalCommission: totalCommission,
      totalWinning: totalWinning,
      totalNet: totalNet,
    );

    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (_) async => pdf.save(),
    );
  }

  static pw.Document _buildPointSummaryPdf({
    required String startDate,
    required String endDate,
    required String rptDateTime,
    required String loginId,
    required String name,
    required String userName,
    required List<ShopReportRow> rows,
    required double totalSale,
    required double totalCommission,
    required double totalWinning,
    required double totalNet,
  }) {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          PdfStyleConstants.thermalRollWidth * PdfPageFormat.inch,
          double.infinity,
        ),
        margin: pw.EdgeInsets.all(PdfStyleConstants.pageMarginDefault),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // HEADER
            buildCenteredText(
              'SHREE LOTTO',
              fontSize: PdfStyleConstants.reportTitleSize,
              bold: true,
            ),
            buildCenteredText(
              'Point Summary',
              fontSize: PdfStyleConstants.sectionHeaderSize,
            ),

            buildVerticalSpace(PdfLayoutConstants.spacingXLarge),
            buildDivider(type: DividerType.dark),
            buildVerticalSpace(PdfLayoutConstants.spacingLarge),

            // METADATA
            buildKeyValueRow(
              'Start Date',
              startDate,
              keyFontSize: PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),
            buildKeyValueRow(
              'End Date',
              endDate,
              keyFontSize: PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),
            buildKeyValueRow(
              'RPT',
              rptDateTime,
              keyFontSize: PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),
            buildKeyValueRow(
              'Login Id',
              loginId,
              keyFontSize: PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),
            buildKeyValueRow(
              'User Name',
              userName,
              keyFontSize: PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),

            buildVerticalSpace(PdfLayoutConstants.spacingLarge),
            buildDivider(type: DividerType.dark),
            buildVerticalSpace(PdfLayoutConstants.spacingLarge),

            // TABLE HEADER
            pw.Row(
              children: [
                buildTableCell('DATE', bold: true),
                buildTableCell('SALE', align: pw.TextAlign.right, bold: true),
                buildTableCell('COMM', align: pw.TextAlign.right, bold: true),
                buildTableCell('WIN', align: pw.TextAlign.right, bold: true),
                buildTableCell('NET', align: pw.TextAlign.right, bold: true),
              ],
            ),
            buildDivider(type: DividerType.dark),

            // TABLE ROWS
            ...rows.map(
              (r) => pw.Padding(
                padding: pw.EdgeInsets.symmetric(
                  vertical: PdfLayoutConstants.spacingXSmall,
                ),
                child: pw.Row(
                  children: [
                    buildTableCell(r.date),
                    buildTableCell(
                      formatNumber(r.totalLoad, 0),
                      align: pw.TextAlign.right,
                    ),
                    buildTableCell(
                      formatNumber(r.commission, 2),
                      align: pw.TextAlign.right,
                    ),
                    buildTableCell(
                      formatNumber(r.winning, 0),
                      align: pw.TextAlign.right,
                    ),
                    buildTableCell(
                      formatNumber(r.endPoint, 2),
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
              ),
            ),

            buildVerticalSpace(PdfLayoutConstants.spacingLarge),
            buildDivider(type: DividerType.dark),
            buildVerticalSpace(PdfLayoutConstants.spacingLarge),

            // TOTALS
            pw.Text(
              'Total',
              style: pw.TextStyle(
                fontSize: PdfStyleConstants.sectionHeaderSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            buildKeyValueRow(
              'Sale',
              formatNumber(totalSale, 0),
              keyFontSize: PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),
            buildKeyValueRow(
              'Commission',
              formatNumber(totalCommission, 2),
              keyFontSize: PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),
            buildKeyValueRow(
              'Winning',
              formatNumber(totalWinning, 0),
              keyFontSize: PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),
            buildKeyValueRow(
              'End Point',
              formatNumber(totalNet, 2),
              keyFontSize: PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),

            buildVerticalSpace(PdfLayoutConstants.spacingXXLarge),
            buildCenteredText(
              '*** THANK YOU ***',
              fontSize: PdfStyleConstants.footerTextSize,
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  // ================= ACCOUNT SUMMARY =================

  static Future<void> printAccountSummary(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final printer = await _getPrinter(context);
    if (printer == null) return;

    final pdf = _buildAccountSummary(data);

    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (_) async => pdf.save(),
    );
  }

  static pw.Document _buildAccountSummary(Map<String, dynamic> data) {
    final pdf = pw.Document();
    final now = DateTime.now();

    String formatDate =
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.year}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          PdfStyleConstants.thermalRollWidth * PdfPageFormat.inch,
          double.infinity,
        ),
        margin: pw.EdgeInsets.all(PdfStyleConstants.pageMarginCompact),
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Shree Lott",
                style: pw.TextStyle(
                  fontSize: PdfStyleConstants.accountTitleSize,
                ),
              ),
              pw.Text(
                "Statement",
                style: pw.TextStyle(
                  fontSize: PdfStyleConstants.accountSubtitleSize,
                ),
              ),

              buildVerticalSpace(PdfLayoutConstants.spacingMedium),

              pw.Text(
                "Date: $formatDate",
                style: pw.TextStyle(
                  fontSize: PdfStyleConstants.accountDataSize,
                ),
              ),
              pw.Text(
                "Sale: ${safeGet(data, 'todaySale')}",
                style: pw.TextStyle(
                  fontSize: PdfStyleConstants.accountDataSize,
                ),
              ),
              pw.Text(
                "Winning Amount : ${safeGet(data, 'todayWinning')}",
                style: pw.TextStyle(
                  fontSize: PdfStyleConstants.accountDataSize,
                ),
              ),
              pw.Text(
                "Commission : ${safeGet(data, 'todayCommission')}",
                style: pw.TextStyle(
                  fontSize: PdfStyleConstants.accountDataSize,
                ),
              ),
              pw.Text(
                "Settlement : ${safeGet(data, 'settlement')}",
                style: pw.TextStyle(
                  fontSize: PdfStyleConstants.accountDataSize,
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // ================= RESULT PRINTING =================

  static Future<void> printResult(
    BuildContext context,
    List<ResultItem> resultItems,
    PdfPageFormat format,
    String drawDate,
    String drawTime,
  ) async {
    final printer = await _getPrinter(context);
    if (printer == null) return;

    final pdf = _buildPrintResult(
      resultItems,
      pageFormat: format,
      drawDate,
      drawTime,
    );

    await Printing.directPrintPdf(
      printer: printer,
      onLayout: (_) async => pdf.save(),
    );
  }

  static pw.Document _buildPrintResult(
    List<ResultItem> resultItems,
    String drawDate,
    String drawTime, {
    required PdfPageFormat pageFormat,
  }) {
    final pdf = pw.Document();
    final bool isRoll80 = pageFormat == PdfPageFormat.roll80;

    final int itemsPerRow = isRoll80
        ? PdfLayoutConstants.gridColumnsResultRoll80
        : PdfLayoutConstants.gridColumnsResultStandard;

    final List<String> numbers = resultItems
        .map((e) => "${e.type}${e.subType}${e.winningNumber}")
        .toList();

    List<List<String>> chunked = [];
    for (int i = 0; i < numbers.length; i += itemsPerRow) {
      chunked.add(
        numbers.sublist(
          i,
          i + itemsPerRow > numbers.length ? numbers.length : i + itemsPerRow,
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.all(PdfStyleConstants.pageMarginDefault),
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SHREE LOTTO',
                style: pw.TextStyle(
                  fontSize: isRoll80 ? 10.0 : 14.0,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Result',
                style: pw.TextStyle(fontSize: isRoll80 ? 8.0 : 12.0),
              ),
              pw.Text(
                "Draw Date : $drawDate",
                style: pw.TextStyle(fontSize: 9.0),
              ),
              // 2026-02-20 08:00:00.130110
              pw.Text(
                "Draw Time : $drawTime",
                style: pw.TextStyle(fontSize: 9.0),
              ),
              // Time of Day(08:00)
              buildVerticalSpace(PdfLayoutConstants.spacingXLarge),
              buildDivider(type: DividerType.dark),
              buildVerticalSpace(PdfLayoutConstants.spacingXLarge),

              // GRID BODY
              ...chunked.map(
                (row) => pw.Padding(
                  padding: pw.EdgeInsets.symmetric(
                    vertical: PdfLayoutConstants.spacingSmall,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: row
                        .map(
                          (number) => pw.Expanded(
                            child: pw.Center(
                              child: pw.Text(
                                number,
                                style: pw.TextStyle(
                                  fontSize: isRoll80 ? 10.0 : 12.0,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),

              buildVerticalSpace(PdfLayoutConstants.spacingXXLarge),
              buildDivider(type: DividerType.dark),

              buildCenteredText(
                '*** THANK YOU ***',
                fontSize: isRoll80 ? 9.0 : 12.0,
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
