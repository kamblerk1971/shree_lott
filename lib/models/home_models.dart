class TimerModel {
  final String nextTimeSlot;
  final int hours;
  final int minutes;
  final int seconds;
  final String currentTime;
  final DateTime targetTime;

  TimerModel({
    required this.nextTimeSlot,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.currentTime,
    required this.targetTime,
  });

  factory TimerModel.fromJson(Map<String, dynamic> json) {
    final rt = json['remaining_time'];
    return TimerModel(
      nextTimeSlot: json['next_time_slot'],
      hours: rt['hours'],
      minutes: rt['minutes'],
      seconds: rt['seconds'],
      currentTime: json['current_time'],
      targetTime: DateTime.parse(json['target_time']),
    );
  }
}

class DrawTimeModel {
  final String nextTimeSlot;
  final String date;

  DrawTimeModel({required this.nextTimeSlot, required this.date});

  factory DrawTimeModel.fromJson(Map<String, dynamic> json) {
    return DrawTimeModel(
      nextTimeSlot: json['next_time_slot'],
      date: json['date'],
    );
  }
}

class TerminalModel {
  final int terminalId;
  final String terminalUser;

  TerminalModel({required this.terminalId, required this.terminalUser});

  factory TerminalModel.fromJson(Map<String, dynamic> json) {
    return TerminalModel(
      terminalId: json['terminalId'],
      terminalUser: json['terminalIdUser'],
    );
  }
}

class LastTransactionModel {
  final String amount;

  LastTransactionModel({required this.amount});

  factory LastTransactionModel.fromJson(Map<String, dynamic> json) {
    return LastTransactionModel(amount: json['lastTransactionAmt']);
  }
}

class ResultItem {
  final String winningNumber;
  final int type;
  final int subType;

  ResultItem({
    required this.winningNumber,
    required this.type,
    required this.subType,
  });

  factory ResultItem.fromJson(Map<String, dynamic> json) {
    return ResultItem(
      winningNumber: json['winning_number'],
      type: json['type'],
      subType: json['sub_type'],
    );
  }
}
