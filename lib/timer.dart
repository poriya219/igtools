import 'dart:async';

import 'package:igtools/persistence.dart';

class DailyTimer {
  static final DailyTimer _instance = DailyTimer._internal();
  factory DailyTimer() => _instance;

  Timer? timer;

  DailyTimer._internal() {
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(minutes: 1), (Timer t) async {
      DateTime now = DateTime.now();
      if (now.hour == 0 && now.minute == 0) {
        final mysqlClient = FrogMysqlClient();
        await mysqlClient.connect();
        await mysqlClient.resetPlans();
      }
    });
  }
}
