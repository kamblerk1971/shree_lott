import 'package:flutter/foundation.dart';

class ShopReportResponse {
  final bool status;
  final String message;
  final ShopReportData reportData;

  ShopReportResponse({
    required this.status,
    required this.message,
    required this.reportData,
  });

  factory ShopReportResponse.fromJson(Map<String, dynamic> json) {
    return ShopReportResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      reportData: ShopReportData.fromJson(json['reportData'] ?? {}),
    );
  }

  @override
  String toString() =>
      'ShopReportResponse(status: $status, message: $message, reportData: $reportData)';
}

class ShopReportData {
  final List<ShopReportRow> rows;
  final ShopReportTotal total;
  final String fromDate;
  final String toDate;

  ShopReportData({
    required this.rows,
    required this.total,
    required this.fromDate,
    required this.toDate,
  });

  factory ShopReportData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> dataWrapper = json['data'] ?? {};
    final List rowList = dataWrapper['data'] ?? [];
    final List totalList = json['data2'] ?? [];
    final Map<String, dynamic> tempData = json['data_temp'] ?? {};

    debugPrint('┌─ ShopReportData.fromJson ───────────────────────');
    debugPrint('│ raw data keys     : ${json.keys.toList()}');
    debugPrint('│ row count         : ${rowList.length}');
    debugPrint('│ totalList count   : ${totalList.length}');
    debugPrint('│ data_temp         : $tempData');

    /// Parse rows
    final List<ShopReportRow> rows =
    rowList.map((e) => ShopReportRow.fromJson(e)).toList();

    /// Parse base total
    final ShopReportTotal baseTotal = totalList.isNotEmpty
        ? ShopReportTotal.fromJson(totalList.first)
        : ShopReportTotal.empty();

    debugPrint('│ baseTotal         : $baseTotal');

    /// Extract extra values from data_temp
    final double extraSale = _toDouble(tempData['sale']);
    final double extraCommission = _toDouble(tempData['commission']);

    debugPrint('│ extraSale         : $extraSale');
    debugPrint('│ extraCommission   : $extraCommission');

    /// Merge data_temp sale & commission into the final total
    final ShopReportTotal finalTotal = baseTotal.copyWith(
      totalLoad: baseTotal.totalLoad + extraSale,
      commission: baseTotal.commission + extraCommission,
    );

    debugPrint('│ finalTotal        : $finalTotal');
    debugPrint('└─────────────────────────────────────────────────');

    return ShopReportData(
      rows: rows,
      total: finalTotal,
      fromDate: json['from_date'] ?? '',
      toDate: json['to_date'] ?? '',
    );
  }

  @override
  String toString() =>
      'ShopReportData(rows: ${rows.length}, total: $total, from: $fromDate, to: $toDate)';
}

class ShopReportRow {
  final String date;
  final double totalLoad;
  final double commission;
  final double winning;
  final double endPoint;

  ShopReportRow({
    required this.date,
    required this.totalLoad,
    required this.commission,
    required this.winning,
    required this.endPoint,
  });

  factory ShopReportRow.fromJson(Map<String, dynamic> json) {
    final row = ShopReportRow(
      date: json['draw_date'] ?? '',
      totalLoad: _toDouble(json['total_load']),
      commission: _toDouble(json['commission']),
      winning: _toDouble(json['winning_amount_paid']),
      endPoint: _toDouble(json['end_point']),
    );
    debugPrint('  ShopReportRow: $row');
    return row;
  }

  @override
  String toString() =>
      'ShopReportRow(date: $date, sale: $totalLoad, comm: $commission, win: $winning, end: $endPoint)';
}

class ShopReportTotal {
  final double totalLoad;
  final double commission;
  final double winning;
  final double endPoint;

  ShopReportTotal({
    required this.totalLoad,
    required this.commission,
    required this.winning,
    required this.endPoint,
  });

  factory ShopReportTotal.fromJson(Map<String, dynamic> json) {
    final total = ShopReportTotal(
      totalLoad: _toDouble(json['total_load']),
      commission: _toDouble(json['commission']),
      winning: _toDouble(json['winning_amount_paid']),
      endPoint: _toDouble(json['total_end_point']),
    );
    debugPrint('  ShopReportTotal.fromJson: $total');
    return total;
  }

  factory ShopReportTotal.empty() {
    debugPrint('  ShopReportTotal.empty() — no data2 found');
    return ShopReportTotal(
      totalLoad: 0.0,
      commission: 0.0,
      winning: 0.0,
      endPoint: 0.0,
    );
  }

  ShopReportTotal copyWith({
    double? totalLoad,
    double? commission,
    double? winning,
    double? endPoint,
  }) {
    return ShopReportTotal(
      totalLoad: totalLoad ?? this.totalLoad,
      commission: commission ?? this.commission,
      winning: winning ?? this.winning,
      endPoint: endPoint ?? this.endPoint,
    );
  }

  @override
  String toString() =>
      'ShopReportTotal(sale: $totalLoad, comm: $commission, win: $winning, end: $endPoint)';
}

/// Safe double parser
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}