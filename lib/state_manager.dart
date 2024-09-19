import 'dart:async';
import 'dart:convert';

import 'package:igtools/models/ig_request.dart';
import 'package:http/http.dart' as http;

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
      print('items list: $items');
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
                  'https://igtools-zs3vzqo-poriua219.globeapp.dev/globe/send'),
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode(IGRequest.toMap(each)));
          print('status 1: ${response.statusCode}');
          print('body: ${response.body}');
          if (response.statusCode == 200) {
            deletedItems.add(each);
          }
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
