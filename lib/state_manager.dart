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
                  'https://graph.instagram.com/v20.0/${each.userID}/media?media_type=STORIES&access_token=${each.token}'),
              body: {'image_url': each.url});
          print('status 1: ${response.statusCode}');
          if (response.statusCode == 200) {
            final r = jsonDecode(response.body);
            String id = r['id'].toString();
            if (id.isNotEmpty && id != 'null') {
              http.Response response2 = await http.post(
                  Uri.parse(
                      'https://graph.instagram.com/v20.0/${each.userID}/media_publish?media_type=STORIES&access_token=${each.token}'),
                  body: {
                    'creation_id': id,
                  });
              print('status 2: ${response2.statusCode}');
            }
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
