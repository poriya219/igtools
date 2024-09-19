import 'dart:async';
import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:igtools/models/ig_request.dart';

class StateManager {
  static final StateManager _instance = StateManager._internal();
  factory StateManager() => _instance;

  List<IGRequest> items = [];
  Timer? timer;

  StateManager._internal() {
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(minutes: 1), (Timer t) async {
      // This is the function that will be executed every 1 minutes.
      // For example, you could modify the items list periodically.
      List<IGRequest> temp = List.from(items);
      List<IGRequest> deletedItems = [];
      for (IGRequest each in temp) {
        String timeString = each.time;
        DateTime time = DateTime.parse(timeString);
        DateTime now = DateTime.now();
        if (time.difference(now).inMinutes == 0) {
          print('send request');
          http.Response response = await http.post(
              Uri.parse(
                  'https://igtools-z94cbbb-poriua219.globeapp.dev/globe/send'),
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode(IGRequest.toMap(each)));
          if (response.statusCode == 200) {
            deletedItems.add(each);
          }
          Hive.init('hive');
          var box = await Hive.openBox('history');
          Map map = box.toMap();
          Map userHistories = map[each.uid] != null ? map[each.uid] as Map : {};
          Map userHistory = userHistories[each.userID] != null
              ? userHistories[each.userID] as Map
              : {};

          userHistory[each.hex] = {
            'status': response.statusCode,
            'time': timeString,
            'type': each.type,
          };
          userHistories[each.userID] = userHistory;
          await box.put(each.uid, userHistories);
        }
        if (time.isBefore(now)) {
          deletedItems.add(each);
        }
      }
      if (deletedItems.isNotEmpty) {
        for (IGRequest i in deletedItems) {
          items.remove(i);
        }
      }
    });
  }
}
