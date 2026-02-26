import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import '../models/shop_report_model.dart';
import '../widgets/show_result_dialog.dart';

// =============================================================
// CONSTANTS
// =============================================================

class PdfStyleConstants {
  // ── Font sizes ──────────────────────────────────────────────
  // All sizes set to minimum 10pt for thermal printer clarity.
  // Sub-10pt text prints faint/illegible on 58mm thermal paper.
  static const double brandFontSize       = 12; // was 10
  static const double legalTextSize       = 11; // was 10
  static const double tableDataSize       = 11; // was 10
  static const double tableHeaderSize     = 11; // was 10
  static const double gridCellFontSize    = 10; // was 8 — minimum readable on thermal
  static const double reportTitleSize     = 15; // was 14
  static const double sectionHeaderSize   = 11; // was 10
  static const double barcodeTextSize     = 11; // was 9
  static const double footerTextSize      = 11; // was 9
  static const double accountTitleSize    = 13; // was 12
  static const double accountSubtitleSize = 11; // was 10
  static const double accountDataSize     = 11; // was 10

  // ── Colors ───────────────────────────────────────────────────
  // Explicit PdfColors.black everywhere.
  // Original grey300/grey400 dividers were near-invisible on thermal paper.
  static const PdfColor textColor    = PdfColors.black;
  static const PdfColor dividerColor = PdfColors.black;
  static const PdfColor headerBg     = PdfColors.grey300;

  // ── Page / margin ────────────────────────────────────────────
  // 58mm roll = 2.25 inch. Original used 2.5 inch — caused right-edge clipping.
  static const double thermalRollWidth  = 2.5; // inches (58mm)
  static const double pageMarginH       =  8.0; // horizontal margin
  static const double pageMarginTop     =  8.0;
  static const double pageMarginBottom  = 14.0; // extra bottom for auto-cut gap
  static const double pageMarginCompact =  6.0;
}

class PdfLayoutConstants {
  // ── Spacing ──────────────────────────────────────────────────
  static const double spXSmall  =  2;
  static const double spSmall   =  3;
  static const double spMedium  =  5;
  static const double spLarge   =  7;
  static const double spXLarge  =  9;
  static const double spXXLarge = 14;

  // ── Divider ──────────────────────────────────────────────────
  // 1.2 is solid and visible on thermal paper.
  static const double dividerHeight = 1.2;

  // ── Number grid column widths (points) ───────────────────────
  // 6 PDF columns: [Num][Qty][Num][Qty][Num][Qty]
  // Available width on 58mm minus 16pt margins ≈ 146pt
  // (24+14) × 3 = 114pt — fits with room for cell padding
  static const double colWidthNum = 24;
  static const double colWidthQty = 14;
  static const int    gridGroups  =  3; // groups of Num+Qty per row

  // ── Result grid ──────────────────────────────────────────────
  static const int gridColumnsResultStandard = 10;
  static const int gridColumnsResultRoll80   =  4;

  // ── Barcode ──────────────────────────────────────────────────
  static const double barcodeWidth  = 140;
  static const double barcodeHeight =  50;
}

// =============================================================
// ENUMS & MODELS
// =============================================================

enum DividerType { light, dark }

class PointSummaryRow {
  final String date;
  final double sale;
  final double commission;
  final double winning;
  final double net;

  const PointSummaryRow({
    required this.date,
    required this.sale,
    required this.commission,
    required this.winning,
    required this.net,
  });
}

// =============================================================
// TICKET PRINT SERVICE
// =============================================================

class TicketPrintService {

  // -----------------------------------------------------------
  // SHARED WIDGET HELPERS
  // -----------------------------------------------------------

  /// Solid black horizontal rule.
  /// Original used grey300/grey400 — invisible on thermal paper.
  static pw.Widget buildDivider({
    double verticalPadding = 0,
    double height = PdfLayoutConstants.dividerHeight,
  }) {
    final line = pw.Container(
      height: height,
      color: PdfStyleConstants.dividerColor,
    );
    if (verticalPadding > 0) {
      return pw.Padding(
        padding: pw.EdgeInsets.symmetric(vertical: verticalPadding),
        child: line,
      );
    }
    return line;
  }

  /// Left-label / right-value row, both in explicit black.
  static pw.Widget buildKeyValueRow(
      String key,
      String value, {
        double keyFontSize   = PdfStyleConstants.legalTextSize,
        double valueFontSize = PdfStyleConstants.legalTextSize,
        double vPad          = PdfLayoutConstants.spXSmall,
        bool   valueBold     = true,
      }) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: vPad),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            key,
            style: pw.TextStyle(
              fontSize: keyFontSize,
              color: PdfStyleConstants.textColor,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: valueFontSize,
              color: PdfStyleConstants.textColor,
              fontWeight: valueBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Expanded table cell — fills its flex slot, explicit black.
  static pw.Widget buildTableCell(
      String text, {
        pw.TextAlign align    = pw.TextAlign.left,
        bool         bold     = false,
        double       fontSize = PdfStyleConstants.tableHeaderSize,
      }) {
    return pw.Expanded(
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          color: PdfStyleConstants.textColor,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Centred single-line text, explicit black.
  static pw.Widget buildCenteredText(
      String text, {
        double fontSize = PdfStyleConstants.barcodeTextSize,
        bool   bold     = false,
      }) {
    return pw.Center(
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          color: PdfStyleConstants.textColor,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Vertical space helper.
  static pw.Widget sp(double h) => pw.SizedBox(height: h);

  // -----------------------------------------------------------
  // UTILITIES
  // -----------------------------------------------------------

  static String formatNumber(dynamic value, int decimals) {
    if (value == null) return (0).toStringAsFixed(decimals);
    if (value is num) return value.toStringAsFixed(decimals);
    return (num.tryParse(value.toString()) ?? 0).toStringAsFixed(decimals);
  }

  static String safeGet(
      Map<String, dynamic> data,
      String key, [
        String fallback = '0',
      ]) =>
      (data[key] ?? fallback).toString();

  /// Format "13:45" → "1:45 PM"
  static String _formatTime(String raw) {
    final parts  = raw.split(':');
    final h24    = int.tryParse(parts[0]) ?? 0;
    final min    = parts.length > 1 ? parts[1] : '00';
    final h12    = h24 % 12 == 0 ? 12 : h24 % 12;
    final ampm   = h24 >= 12 ? 'PM' : 'AM';
    return '$h12:$min $ampm';
  }

  // -----------------------------------------------------------
  // PRINTER MANAGEMENT
  // -----------------------------------------------------------

  static Future<Printer?> _getPrinter(BuildContext context) async {
    final box = Hive.isBoxOpen('printerBox')
        ? Hive.box('printerBox')
        : await Hive.openBox('printerBox');

    Printer? printer;
    final savedName = box.get('printer_name') as String?;

    if (savedName != null) {
      final all = await Printing.listPrinters();
      printer   = _matchPrinter(all, savedName);
    }

    printer ??= await Printing.pickPrinter(context: context);

    if (printer != null) {
      await box.put('printer_name', printer.name);
    }
    return printer;
  }

  static Printer? _matchPrinter(List<Printer> list, String name) {
    if (list.isEmpty) return null;
    return list.firstWhere(
          (p) => p.name == name,
      orElse: () => list.first,
    );
  }

// -----------------------------------------------------------
  // TICKET PRINT — PUBLIC ENTRY POINT
  // -----------------------------------------------------------

  static Future<void> printTicket({
    required BuildContext    context,
    required Map<String,int> selections,
    required List<String>    ticketIds,
    required List<String>    ticketTimes,
    required List<int>       ticketsAmounts,
    required String          date,
    required int             totalQty,
    required String          userId,
  }) async {
    final printer = await _getPrinter(context);
    if (printer == null) return;

    final pdf = pw.Document();

    for (int i = 0; i < ticketIds.length; i++) {
      final ticketId     = 'SL${ticketIds[i]}';
      final time         = i < ticketTimes.length    ? ticketTimes[i]    : ticketTimes.first;
      final ticketAmount = i < ticketsAmounts.length ? ticketsAmounts[i] : ticketsAmounts.first;

      // Sort entries once
      final entries = selections.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      // ── MultiPage: NO header/footer callbacks ─────────────────
      // All content lives in build so it flows naturally across
      // pages. When the grid is too tall for one page, MultiPage
      // simply continues on the next — no clipping, no repeated
      // brand/metadata blocks.
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat(
            PdfStyleConstants.thermalRollWidth * PdfPageFormat.inch,
            PdfPageFormat.a4.height,
          ),
          margin: pw.EdgeInsets.fromLTRB(
            PdfStyleConstants.pageMarginH,
            PdfStyleConstants.pageMarginTop,
            PdfStyleConstants.pageMarginH,
            PdfStyleConstants.pageMarginBottom,
          ),
          build: (_) => [

            // ── BRAND ───────────────────────────────────────────
            pw.Text(
              'Shree Lott',
              style: pw.TextStyle(
                fontSize:   PdfStyleConstants.brandFontSize,
                fontWeight: pw.FontWeight.bold,
                color:      PdfStyleConstants.textColor,
              ),
            ),
            pw.Text(
              'FOR AMUSEMENT ONLY',
              style: pw.TextStyle(
                fontSize: PdfStyleConstants.brandFontSize,
                color:    PdfStyleConstants.textColor,
              ),
            ),

            sp(PdfLayoutConstants.spSmall),
            buildDivider(),
            sp(PdfLayoutConstants.spSmall),

            // ── METADATA ────────────────────────────────────────
            buildKeyValueRow('Terminal ID', userId),
            buildKeyValueRow('Draw Date',   date),
            buildKeyValueRow('Time',        _formatTime(time)),
            buildKeyValueRow('Ticket ID',   ticketId),

            sp(PdfLayoutConstants.spSmall),
            buildDivider(),
            sp(PdfLayoutConstants.spSmall),

            // ── NUMBER GRID ─────────────────────────────────────
            // pw.Table inside MultiPage is paginated row-by-row.
            // When a row does not fit on the current page, MultiPage
            // starts a new page and continues from that exact row —
            // no content is ever clipped regardless of entry count.
            _buildNumberGrid(entries),

            sp(PdfLayoutConstants.spSmall),
            buildDivider(),
            sp(PdfLayoutConstants.spSmall),

            // ── SUMMARY ─────────────────────────────────────────
            buildKeyValueRow(
              'Points',
              ticketAmount.toString(),
              vPad: PdfLayoutConstants.spSmall,
            ),
            buildKeyValueRow(
              'Total Qty',
              totalQty.toString(),
              vPad: PdfLayoutConstants.spSmall,
            ),

            sp(PdfLayoutConstants.spMedium),

            // ── BARCODE ─────────────────────────────────────────
            pw.Center(
              child: pw.BarcodeWidget(
                barcode:  pw.Barcode.code128(),
                data:     ticketId,
                width:    PdfLayoutConstants.barcodeWidth,
                height:   PdfLayoutConstants.barcodeHeight,
                color:    PdfStyleConstants.textColor,
                drawText: false,
              ),
            ),

            sp(PdfLayoutConstants.spSmall),

            buildCenteredText(
              ticketId,
              fontSize: PdfStyleConstants.barcodeTextSize,
              bold:     true,
            ),
          ],
        ),
      );
    }

    await Printing.directPrintPdf(
      printer:  printer,
      onLayout: (_) async => pdf.save(),
    );
  }

  // -----------------------------------------------------------
  // NUMBER GRID
  // -----------------------------------------------------------
  //
  // Layout on 58mm paper (margin 8pt each side = 146pt available):
  //
  //  ┌────────┬────┬────────┬────┬────────┬────┐
  //  │  Num   │Qty │  Num   │Qty │  Num   │Qty │
  //  ├────────┼────┼────────┼────┼────────┼────┤
  //  │  0000  │ 1  │  0001  │ 1  │  0002  │ 1  │
  //  │  0003  │ 1  │  0004  │ 1  │  0005  │ 1  │
  //  │   …    │ …  │   …    │ …  │   …    │ …  │
  //  └────────┴────┴────────┴────┴────────┴────┘
  //
  // Column widths: Num=24pt, Qty=14pt → (24+14)×3 = 114pt ✓
  //
  // Inside pw.MultiPage the table is split row-by-row across
  // pages automatically — no clipping, no manual chunking needed.

  static pw.Widget _buildNumberGrid(List<MapEntry<String, int>> entries) {
    const int g = PdfLayoutConstants.gridGroups; // 3

    final hStyle = pw.TextStyle(
      fontSize:   PdfStyleConstants.gridCellFontSize,
      fontWeight: pw.FontWeight.bold,
      color:      PdfStyleConstants.textColor,
    );
    final dStyle = pw.TextStyle(
      fontSize: PdfStyleConstants.gridCellFontSize,
      color:    PdfStyleConstants.textColor,
    );

    final border = pw.TableBorder.all(
      color: PdfStyleConstants.textColor,
      width: 0.8,
    );

    const colWidths = {
      0: pw.FixedColumnWidth(PdfLayoutConstants.colWidthNum),
      1: pw.FixedColumnWidth(PdfLayoutConstants.colWidthQty),
      2: pw.FixedColumnWidth(PdfLayoutConstants.colWidthNum),
      3: pw.FixedColumnWidth(PdfLayoutConstants.colWidthQty),
      4: pw.FixedColumnWidth(PdfLayoutConstants.colWidthNum),
      5: pw.FixedColumnWidth(PdfLayoutConstants.colWidthQty),
    };

    // ── Header row ────────────────────────────────────────────
    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: List.generate(
        g,
            (_) => [
          _gridCell('Num', hStyle, pw.TextAlign.center),
          _gridCell('Qty', hStyle, pw.TextAlign.center),
        ],
      ).expand((x) => x).toList(),
    );

    // ── Data rows ─────────────────────────────────────────────
    final List<pw.TableRow> dataRows = [];

    for (int i = 0; i < entries.length; i += g) {
      final cells = <pw.Widget>[];

      for (int c = 0; c < g; c++) {
        if (i + c < entries.length) {
          final e = entries[i + c];
          cells
            ..add(_gridCell(e.key.padLeft(4, '0'), dStyle, pw.TextAlign.center))
            ..add(_gridCell(e.value.toString(),     dStyle, pw.TextAlign.center));
        } else {
          // Filler keeps the border grid intact on incomplete rows
          cells
            ..add(_gridCell('', dStyle, pw.TextAlign.center))
            ..add(_gridCell('', dStyle, pw.TextAlign.center));
        }
      }

      dataRows.add(pw.TableRow(children: cells));
    }

    return pw.Table(
      border:       border,
      columnWidths: colWidths,
      children:     [headerRow, ...dataRows],
    );
  }

  /// Single cell in the number grid with consistent inner padding.
  static pw.Widget _gridCell(
      String       text,
      pw.TextStyle style,
      pw.TextAlign align,
      ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: pw.Text(text, style: style, textAlign: align),
    );
  }
  // -----------------------------------------------------------
  // POINT SUMMARY REPORT
  // -----------------------------------------------------------

  static Future<void> printPointSummaryReport({
    required BuildContext      context,
    required String            startDate,
    required String            endDate,
    required String            rptDateTime,
    required String            loginId,
    required String            name,
    required String            userName,
    required List<ShopReportRow> rows,
    required double            totalSale,
    required double            totalCommission,
    required double            totalWinning,
    required double            totalNet,
  }) async {
    final printer = await _getPrinter(context);
    if (printer == null) return;

    final pdf = _buildPointSummaryPdf(
      startDate:       startDate,
      endDate:         endDate,
      rptDateTime:     rptDateTime,
      loginId:         loginId,
      name:            name,
      userName:        userName,
      rows:            rows,
      totalSale:       totalSale,
      totalCommission: totalCommission,
      totalWinning:    totalWinning,
      totalNet:        totalNet,
    );

    await Printing.directPrintPdf(
      printer:  printer,
      onLayout: (_) async => pdf.save(),
    );
  }

  static pw.Document _buildPointSummaryPdf({
    required String            startDate,
    required String            endDate,
    required String            rptDateTime,
    required String            loginId,
    required String            name,
    required String            userName,
    required List<ShopReportRow> rows,
    required double            totalSale,
    required double            totalCommission,
    required double            totalWinning,
    required double            totalNet,
  }) {
    final pdf = pw.Document();


    final now = DateTime.now();

    final rptDate = DateFormat('dd-MM-yyyy').format(now);
    final rptTime = DateFormat('hh:mm:ss a').format(now);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          PdfStyleConstants.thermalRollWidth * PdfPageFormat.inch,
          double.infinity,
        ),
        margin: pw.EdgeInsets.fromLTRB(
          PdfStyleConstants.pageMarginH,
          PdfStyleConstants.pageMarginTop,
          PdfStyleConstants.pageMarginH,
          PdfStyleConstants.pageMarginBottom,
        ),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            // ── Header ──────────────────────────────────────
            buildCenteredText(
              'SHREE LOTTO',
              fontSize: PdfStyleConstants.reportTitleSize,
              bold:     true,
            ),
            sp(PdfLayoutConstants.spXSmall),
            buildCenteredText(
              'Point Summary',
              fontSize: PdfStyleConstants.sectionHeaderSize,
            ),

            sp(PdfLayoutConstants.spLarge),
            buildDivider(),
            sp(PdfLayoutConstants.spMedium),

            // ── Metadata ────────────────────────────────────
            buildKeyValueRow(
              'Start Date', startDate,
              keyFontSize:   PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),
            buildKeyValueRow(
              'End Date', endDate,
              keyFontSize:   PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),
            buildKeyValueRow(
              'Date', rptDate,
              keyFontSize: PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),

            buildKeyValueRow(
              'Time', rptTime,
              keyFontSize: PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),
            buildKeyValueRow(
              'Login ID', loginId,
              keyFontSize:   PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),
            buildKeyValueRow(
              'User Name', userName,
              keyFontSize:   PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),

            sp(PdfLayoutConstants.spMedium),
            buildDivider(),
            sp(PdfLayoutConstants.spMedium),

            // ── Rows — one per entry, shown as key-value blocks ──
            // Each ShopReportRow is rendered as a labelled block
            // separated by a light divider, so every field is
            // clearly readable on 58mm thermal paper without
            // squeezing 5 columns into a narrow table.
            ...rows.asMap().entries.map((entry) {
              final idx = entry.key;
              final r   = entry.value;
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [

                  // ── Entry header: row number + date ─────
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(
                        top: PdfLayoutConstants.spSmall,
                        bottom: PdfLayoutConstants.spXSmall),
                    child: pw.Text(
                      '#${idx + 1}  ${r.date}',
                      style: pw.TextStyle(
                        fontSize:   PdfStyleConstants.sectionHeaderSize,
                        fontWeight: pw.FontWeight.bold,
                        color:      PdfStyleConstants.textColor,
                      ),
                    ),
                  ),

                  // ── Sale ────────────────────────────────
                  buildKeyValueRow(
                    'Sale',
                    formatNumber(r.totalLoad, 0),
                    keyFontSize:   PdfStyleConstants.sectionHeaderSize,
                    valueFontSize: PdfStyleConstants.sectionHeaderSize,
                    vPad:          PdfLayoutConstants.spXSmall,
                  ),

                  // ── Commission ──────────────────────────
                  buildKeyValueRow(
                    'Commission',
                    formatNumber(r.commission, 2),
                    keyFontSize:   PdfStyleConstants.sectionHeaderSize,
                    valueFontSize: PdfStyleConstants.sectionHeaderSize,
                    vPad:          PdfLayoutConstants.spXSmall,
                  ),

                  // ── Winning ─────────────────────────────
                  buildKeyValueRow(
                    'Winning',
                    formatNumber(r.winning, 0),
                    keyFontSize:   PdfStyleConstants.sectionHeaderSize,
                    valueFontSize: PdfStyleConstants.sectionHeaderSize,
                    vPad:          PdfLayoutConstants.spXSmall,
                  ),

                  // ── Net / End Point ──────────────────────
                  buildKeyValueRow(
                    'End Point',
                    formatNumber(r.endPoint, 2),
                    keyFontSize:   PdfStyleConstants.sectionHeaderSize,
                    valueFontSize: PdfStyleConstants.sectionHeaderSize,
                    vPad:          PdfLayoutConstants.spXSmall,
                  ),

                  sp(PdfLayoutConstants.spSmall),
                  buildDivider(),
                ],
              );
            }),

            sp(PdfLayoutConstants.spMedium),

            // ── Totals ──────────────────────────────────────
            pw.Text(
              'Total',
              style: pw.TextStyle(
                fontSize:   PdfStyleConstants.sectionHeaderSize,
                fontWeight: pw.FontWeight.bold,
                color:      PdfStyleConstants.textColor,
              ),
            ),
            buildKeyValueRow(
              'Sale',
              formatNumber(totalSale, 0),
              keyFontSize:   PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),
            buildKeyValueRow(
              'Commission',
              formatNumber(totalCommission, 2),
              keyFontSize:   PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),
            buildKeyValueRow(
              'Winning',
              formatNumber(totalWinning, 0),
              keyFontSize:   PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),
            buildKeyValueRow(
              'End Point',
              formatNumber(totalNet, 2),
              keyFontSize:   PdfStyleConstants.sectionHeaderSize,
              valueFontSize: PdfStyleConstants.sectionHeaderSize,
            ),

            sp(PdfLayoutConstants.spXXLarge),

            buildCenteredText(
              '*** THANK YOU ***',
              fontSize: PdfStyleConstants.footerTextSize,
              bold:     true,
            ),
          ],
        ),
      ),
    );

    return pdf;
  }

  // -----------------------------------------------------------
  // ACCOUNT SUMMARY
  // -----------------------------------------------------------

  static Future<void> printAccountSummary(
      BuildContext context,
      Map<String,dynamic> data,
      ) async {
    final printer = await _getPrinter(context);
    if (printer == null) return;

    await Printing.directPrintPdf(
      printer:  printer,
      onLayout: (_) async => _buildAccountSummary(data).save(),
    );
  }

  static pw.Document _buildAccountSummary(Map<String,dynamic> data) {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('dd-MM-yyyy').format(now);
    final timeStr = DateFormat('hh:mm:ss a').format(now);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          PdfStyleConstants.thermalRollWidth * PdfPageFormat.inch,
          double.infinity,
        ),
        margin: pw.EdgeInsets.all(PdfStyleConstants.pageMarginCompact),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            pw.Text(
              'Shree Lott',
              style: pw.TextStyle(
                fontSize:   PdfStyleConstants.accountTitleSize,
                fontWeight: pw.FontWeight.bold,
                color:      PdfStyleConstants.textColor,
              ),
            ),
            pw.Text(
              'Statement',
              style: pw.TextStyle(
                fontSize: PdfStyleConstants.accountSubtitleSize,
                color:    PdfStyleConstants.textColor,
              ),
            ),

            sp(PdfLayoutConstants.spMedium),
            buildDivider(),
            sp(PdfLayoutConstants.spMedium),

            _acctRow('Date',             dateStr),
            _acctRow('Time',             timeStr),
            _acctRow('Sale',             safeGet(data, 'todaySale')),
            _acctRow('Winning Amount',   safeGet(data, 'todayWinning')),
            _acctRow('Commission',       safeGet(data, 'todayCommission')),
            _acctRow('Settlement',       safeGet(data, 'settlement')),
          ],
        ),
      ),
    );

    return pdf;
  }

  static pw.Widget _acctRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(
          vertical: PdfLayoutConstants.spXSmall),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: PdfStyleConstants.accountDataSize,
                  color: PdfStyleConstants.textColor)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize:   PdfStyleConstants.accountDataSize,
                  fontWeight: pw.FontWeight.bold,
                  color:      PdfStyleConstants.textColor)),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // RESULT PRINTING
  // -----------------------------------------------------------

  static Future<void> printResult(
      BuildContext       context,
      List<ResultItem>   resultItems,
      PdfPageFormat      format,
      String             drawDate,
      String             drawTime,
      ) async {
    final printer = await _getPrinter(context);
    if (printer == null) return;

    await Printing.directPrintPdf(
      printer:  printer,
      onLayout: (_) async =>
          _buildPrintResult(resultItems, drawDate, drawTime,
              pageFormat: format)
              .save(),
    );
  }

  static pw.Document _buildPrintResult(
      List<ResultItem> resultItems,
      String           drawDate,
      String           drawTime, {
        required PdfPageFormat pageFormat,
      }) {
    final pdf      = pw.Document();
    final isRoll80 = pageFormat == PdfPageFormat.roll80;

    final itemsPerRow = isRoll80
        ? PdfLayoutConstants.gridColumnsResultRoll80
        : PdfLayoutConstants.gridColumnsResultStandard;

    final numbers = resultItems
        .map((e) => '${e.type}${e.subType}${e.winningNumber}')
        .toList();

    // Chunk into rows of itemsPerRow
    final List<List<String>> chunked = [];
    for (int i = 0; i < numbers.length; i += itemsPerRow) {
      chunked.add(numbers.sublist(
        i,
        (i + itemsPerRow).clamp(0, numbers.length),
      ));
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          PdfStyleConstants.thermalRollWidth * PdfPageFormat.inch,
          double.infinity,
        ),
        margin: pw.EdgeInsets.fromLTRB(
          PdfStyleConstants.pageMarginH,
          PdfStyleConstants.pageMarginTop,
          PdfStyleConstants.pageMarginH,
          PdfStyleConstants.pageMarginBottom,
        ),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            // ── Header ──────────────────────────────────────
            pw.Text(
              'SHREE LOTTO',
              style: pw.TextStyle(
                fontSize:   isRoll80 ? 12.0 : 15.0, // was 11/14 — bumped for thermal
                fontWeight: pw.FontWeight.bold,
                color:      PdfStyleConstants.textColor,
              ),
            ),
            pw.Text(
              'Result',
              style: pw.TextStyle(
                fontSize: isRoll80 ? 11.0 : 13.0, // was 9/12 — bumped for thermal
                color:    PdfStyleConstants.textColor,
              ),
            ),
            sp(PdfLayoutConstants.spXSmall),
            pw.Text(
              'Draw Date : $drawDate',
              style: pw.TextStyle(
                  fontSize: 11.0, // was 9.0 — bumped for thermal
                  color: PdfStyleConstants.textColor),
            ),
            pw.Text(
              'Draw Time : $drawTime',
              style: pw.TextStyle(
                  fontSize: 11.0, // was 9.0 — bumped for thermal
                  color: PdfStyleConstants.textColor),
            ),

            sp(PdfLayoutConstants.spLarge),
            buildDivider(),
            sp(PdfLayoutConstants.spLarge),

            // ── Result grid ─────────────────────────────────
            ...chunked.map((row) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(
                  vertical: PdfLayoutConstants.spSmall),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: row.map((num) => pw.Expanded(
                  child: pw.Center(
                    child: pw.Text(
                      num,
                      style: pw.TextStyle(
                        fontSize:   isRoll80 ? 11.0 : 13.0, // was 10/12 — bumped for thermal
                        fontWeight: pw.FontWeight.bold,
                        color:      PdfStyleConstants.textColor,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            )),

            sp(PdfLayoutConstants.spXXLarge),
            buildDivider(),
            sp(PdfLayoutConstants.spSmall),

            buildCenteredText(
              '*** THANK YOU ***',
              fontSize: isRoll80 ? 11.0 : 13.0, // was 9/12 — bumped for thermal
              bold:     true,
            ),
          ],
        ),
      ),
    );

    return pdf;
  }
}