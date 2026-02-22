import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:shreelott/service/ticket_print_service.dart';

import '../models/shop_report_model.dart';
import 'wallet_controller.dart';

/// ============================================================
/// API CONSTANTS
/// ============================================================
class ApiConstants {
  static const String baseUrl = "https://bid.grocerkings.in/api";

  static const String timer = "/get-timer";
  static const String drawTime = "/get-drawtime";
  static const String terminalId = "/get-terminal-id";
  static const String lastTransaction = "/get-last-transaction-id";
  static const String getWalletBalance = "/get-wallet-balance";
  static const String result = "/get-result";
  static const String transaction = "/transaction";
  static const String cancelBet = "/bet-cancel";
  static const String claim = "/claim";
  static const String shopReport = "/shop-report/1";
  static const String printTicket = "/reprint";
}

/// ============================================================
/// API CLIENT (SAFE + DRY)
/// ============================================================
class ApiClient {
  final http.Client _client = http.Client();

  /// 🔑 READ TOKEN FROM HIVE
  static Future<String> getToken() async {
    final box = await Hive.openBox('app');
    return box.get('token', defaultValue: '') as String;
  }

  /// ===================== GET =====================
  Future<Map<String, dynamic>> get(String url) async {
    final token = await getToken();

    final response = await _client.get(
      Uri.parse(url),
      headers: {
        "Accept": "application/json",
        if (token.isNotEmpty) "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("HTTP ${response.statusCode}");
    }

    if (response.body.trim().isEmpty) {
      throw Exception("Empty response body");
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception("Invalid JSON format");
    }

    return decoded;
  }

  /// ===================== POST =====================
  Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();

    final response = await _client.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    print(response.body);

    if (response.statusCode != 200) {
      throw Exception("HTTP ${response.statusCode}");
    }

    if (response.body.trim().isEmpty) {
      throw Exception("Empty response body");
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception("Invalid JSON format");
    }

    return decoded;
  }

  void dispose() {
    _client.close();
  }
}

/// ============================================================
/// MODELS (UNCHANGED)
/// ============================================================

class TimerModel {
  final String nextTimeSlot;
  final RemainingTime remainingTime;
  final String currentTime;
  final DateTime targetTime;

  TimerModel({
    required this.nextTimeSlot,
    required this.remainingTime,
    required this.currentTime,
    required this.targetTime,
  });

  factory TimerModel.fromJson(Map<String, dynamic> json) {
    return TimerModel(
      nextTimeSlot: json["next_time_slot"]?.toString() ?? "--",
      remainingTime: RemainingTime.fromJson(json["remaining_time"] ?? {}),
      currentTime: json["current_time"]?.toString() ?? "--",
      targetTime:
          DateTime.tryParse(json["target_time"]?.toString() ?? "") ??
          DateTime.now(),
    );
  }
}

class RemainingTime {
  final int hours;
  final int minutes;
  final int seconds;
  final int totalSeconds;

  RemainingTime({
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.totalSeconds,
  });

  factory RemainingTime.fromJson(Map<String, dynamic> json) {
    return RemainingTime(
      hours: int.tryParse(json["hours"]?.toString() ?? "0") ?? 0,
      minutes: int.tryParse(json["minutes"]?.toString() ?? "0") ?? 0,
      seconds: int.tryParse(json["seconds"]?.toString() ?? "0") ?? 0,
      totalSeconds: int.tryParse(json["total_seconds"]?.toString() ?? "0") ?? 0,
    );
  }
}

class DrawTimeModel {
  final String nextTimeSlot;
  final String date;

  DrawTimeModel({required this.nextTimeSlot, required this.date});

  factory DrawTimeModel.fromJson(Map<String, dynamic> json) {
    return DrawTimeModel(
      nextTimeSlot: json["next_time_slot"]?.toString() ?? "--",
      date: json["date"]?.toString().replaceAll("-", "/") ?? "--",
    );
  }
}

class TerminalModel {
  final int terminalId;
  final String terminalUser;

  TerminalModel({required this.terminalId, required this.terminalUser});

  factory TerminalModel.fromJson(Map<String, dynamic> json) {
    return TerminalModel(
      terminalId: int.tryParse(json["terminalId"]?.toString() ?? "0") ?? 0,
      terminalUser: json["terminalIdUser"]?.toString() ?? "--",
    );
  }
}

class LastTransactionModel1 {
  final String amount;

  LastTransactionModel1({required this.amount});

  factory LastTransactionModel1.fromJson(Map<String, dynamic> json) {
    return LastTransactionModel1(
      amount: json["lastTransactionAmt"]?.toString() ?? "0",
    );
  }
}

class WalletBalance {
  final String amount;

  WalletBalance({required this.amount});

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(amount: json["wallet"]?.toString() ?? "0");
  }
}

class ResultModel {
  final String winningNumber;
  final int type;
  final int subType;

  ResultModel({
    required this.winningNumber,
    required this.type,
    required this.subType,
  });

  factory ResultModel.fromJson(Map<String, dynamic> json) {
    return ResultModel(
      winningNumber: json["winning_number"]?.toString() ?? "--",
      type: int.tryParse(json["type"]?.toString() ?? "0") ?? 0,
      subType: int.tryParse(json["sub_type"]?.toString() ?? "0") ?? 0,
    );
  }
}

class TransactionModel {
  final String pid;
  final String totalLoad;
  final String slot;
  final String status;

  TransactionModel({
    required this.pid,
    required this.totalLoad,
    required this.slot,
    required this.status,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      pid: json["p_id"]?.toString() ?? "--",
      totalLoad: json["total_load"]?.toString() ?? "0",
      slot: json["slot"]?.toString() ?? "--",
      status: json["status"]?.toString() ?? "--",
    );
  }
}

/// ============================================================
/// HOME CONTROLLER (FIXED & DRY)
/// ============================================================
class HomeController {
  final ApiClient _api = ApiClient();

  Future<TimerModel> getTimer() async {
    final json = await _api.get(ApiConstants.baseUrl + ApiConstants.timer);
    print(json);
    return TimerModel.fromJson(json);
  }

  Future<DrawTimeModel> getDrawTime() async {
    final json = await _api.get(ApiConstants.baseUrl + ApiConstants.drawTime);
    print(json);

    return DrawTimeModel.fromJson(json);
  }

  Future<TerminalModel> getTerminalId() async {
    final json = await _api.get(ApiConstants.baseUrl + ApiConstants.terminalId);
    print(json);

    return TerminalModel.fromJson(json);
  }

  Future<LastTransactionModel1> getLastTransaction() async {
    final json = await _api.get(
      ApiConstants.baseUrl + ApiConstants.lastTransaction,
    );
    print(json);

    return LastTransactionModel1.fromJson(json);
  }

  Future<WalletBalance> getWalletBalance() async {
    final WalletController walletController = Get.find<WalletController>();
    final json = await _api.get(
      ApiConstants.baseUrl + ApiConstants.getWalletBalance,
    );

    print("Wallet API Response: $json");

    // Parse model from API response
    final walletBalance = WalletBalance.fromJson(json);

    // Safely extract amount
    final double amount = double.tryParse(walletBalance.amount ?? "0") ?? 0.0;

    // Update wallet controller
    walletController.setBalance(amount);

    return walletBalance;
  }

  Future<List<ResultModel>> getInitResults() async {
    final json = await _api.get(
      "${ApiConstants.baseUrl}${ApiConstants.result}",
    );

    print(json);

    final List list = json["result"] ?? [];
    return list.map((e) => ResultModel.fromJson(e)).toList();
  }

  Future<List<TransactionModel>> getTransactions() async {
    final json = await _api.get(
      ApiConstants.baseUrl + ApiConstants.transaction,
    );

    if (json["status"] != true) return [];

    final List list = json["all_ticket"] ?? [];
    return list.map((e) => TransactionModel.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> cancelBet({
    required String id,
  }) async {
    try {
      debugPrint("════════════ CANCEL BET START ════════════");
      debugPrint("🎟 Ticket ID → $id");

      final json = await _api.post(
        ApiConstants.baseUrl + ApiConstants.cancelBet,
        {"id": id},
      );

      debugPrint("📦 API RESPONSE → $json");

      if (json == null) {
        return {
          "success": false,
          "message": "No response from server",
        };
      }

      final bool status = json["status"] == true;
      final String message =
          json["message"]?.toString() ??
              (status ? "Bet cancelled successfully" : "Cancel failed");

      debugPrint("✔ Status → $status");
      debugPrint("📝 Message → $message");
      debugPrint("════════════ CANCEL BET END ════════════");

      return {
        "success": status,
        "message": message,
        "data": json["data"], // optional if backend sends
        "wallet":json["wallet"]
      };

    } catch (e, stack) {
      debugPrint("❌ cancelBet Error → $e");
      debugPrint("📛 StackTrace → $stack");

      return {
        "success": false,
        "message": "Something went wrong. Please try again.",
      };
    }
  }

  Future<Map<String, dynamic>> claim({
    required String id,
  }) async {
    try {
      final cleanId = id.replaceAll(RegExp(r'sl', caseSensitive: false), '');

      final json = await _api.post(ApiConstants.baseUrl + ApiConstants.claim, {
        "id": cleanId,
      });

      // {"message":"Payment Completed","walate":"2239","acc_paid":900,
      //  "sale":210,"commission":21,"winner":900,"status":true}
      // pay now button
      // onclick -> account summary (add)
      // {"message":"Already Claimed","status":true,"winner":900}
      // {"status":false,"message":"Please Enter valid ticket no."}

      final bool status = json["status"] == 1 || json["status"] == true;
      final String message = json["message"]?.toString()
          ?? json["msg"]?.toString()
          ?? "Please enter a valid ticket number.";

      return {
        "status"     : status,
        "message"    : message,
        "winner"     : json["winner"]     ?? 0,
        "walate"     : json["walate"]     ?? 0,
        "acc_paid"   : json["acc_paid"]   ?? 0,
        "sale"       : json["sale"]       ?? 0,
        "commission" : json["commission"] ?? 0,
      };
    } catch (e) {
      return {
        "status"     : false,
        "message"    : "Something went wrong. Please try again.",
        "winner"     : 0,
        "walate"     : 0,
        "acc_paid"   : 0,
        "sale"       : 0,
        "commission" : 0,
      };
    }
  }  /// ===================== SHOP REPORT =====================
  Future<ShopReportResponse?> fetchReport({
    required String from,
    required String to,
  }) async {
    try {
      final json = await _api.post(
        ApiConstants.baseUrl + ApiConstants.shopReport,
        {"from": from, "to": to},
      );

      if (json["status"] != true) return null;

      return ShopReportResponse.fromJson(json);
    } catch (e) {
      debugPrint("❌ ShopReport Error: $e");
      return null;
    }
  }

  Future<void> reprintTicket({
    required String ticketId,
    required String userId,
    required BuildContext context,
  }) async {
    try {
      final url =
          "${ApiConstants.baseUrl}${ApiConstants.printTicket}/$ticketId";

      debugPrint("════════════ REPRINT START ════════════");
      debugPrint("🌐 URL → $url");

      final json = await _api.get(url);

      if (json == null || json["status"] != true) {
        debugPrint("❌ Invalid API response");
        return;
      }

      final List<dynamic> dataList = json["data"] ?? [];
      final List<String> parentAll =
          (json["parent_all"] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
              [];

      final String drawDate = json["draw_date"] ?? "";
      final String ticketTime = json["walate2"] ?? "";

      final Map<String, int> selections = {};

      int totalQty = 0;
      int totalAmount = 0;

      // ================= PROCESS EACH ROW =================
      for (var row in dataList) {
        debugPrint("🧾 Processing Row → $row");

        final int c = int.tryParse(row["c"].toString()) ?? 0;
        final int s = int.tryParse(row["s"].toString()) ?? 0;
        final int point = int.tryParse(row["point"].toString()) ?? 1;

        final int rowAmount =
            int.tryParse(row["total_bet_load"].toString()) ?? 0;

        totalAmount += rowAmount;   // ✅ Backend amount used directly

        int rowQty = 0;

        row.forEach((key, value) {
          if (key.startsWith("c") &&
              key.length == 3 &&
              value != null) {

            final int columnAmount =
                int.tryParse(value.toString()) ?? 0;

            if (columnAmount <= 0) return;

            // ✅ qty = amount / point
            final int qty =
            (point > 0) ? (columnAmount ~/ point) : 0;

            if (qty <= 0) return;

            final String lastTwoDigits = key.substring(1);
            final String fullNumber =
            "$c$s$lastTwoDigits".padLeft(4, '0');

            debugPrint(
                "➡ $fullNumber | ColumnAmt: $columnAmount | Qty: $qty");

            rowQty += qty;

            selections.update(
              fullNumber,
                  (existing) => existing + qty,
              ifAbsent: () => qty,
            );
          }
        });

        totalQty += rowQty;

        debugPrint(
            "✔ Row Summary → Qty: $rowQty | Amount: $rowAmount");
        debugPrint("------------------------------------------------");
      }

      final sortedSelections = Map.fromEntries(
        selections.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      );

      debugPrint("📊 FINAL SELECTION MAP:");
      sortedSelections.forEach((num, qty) {
        debugPrint("   $num → $qty");
      });

      debugPrint("════════════ FINAL TOTALS ════════════");
      debugPrint("🧮 Total Qty → $totalQty");
      debugPrint("💰 Total Amount → $totalAmount");
      debugPrint("🎟 Tickets → $parentAll");
      debugPrint("════════════ PRINTING ════════════");

      await TicketPrintService.printTicket(
        context: context,
        selections: sortedSelections,
        ticketIds: parentAll,
        ticketTimes:
        List.generate(parentAll.length, (_) => ticketTime),
        date: drawDate,
        totalQty: totalQty,
        ticketsAmounts:
        List.generate(parentAll.length, (_) => totalAmount),
        userId: userId,
      );

      debugPrint("════════════ REPRINT END ════════════");

    } catch (e, stack) {
      debugPrint("❌ reprintTicket Error → $e");
      debugPrint("📛 StackTrace → $stack");
    }
  }


  void dispose() {
    _api.dispose();
  }
}
