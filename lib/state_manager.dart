import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:igtools/network.dart';
import 'package:igtools/persistence.dart';
import 'package:postgres/postgres.dart';

class StateManager {
  static final StateManager _instance = StateManager._internal();
  factory StateManager() => _instance;

  Timer? timer;

  StateManager._internal() {
    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(minutes: 1), (Timer t) async {
      final mysqlClient = FrogMysqlClient();
      Network network = Network();
      List<int> ids = [];
      List<int> statuses = [];
      List<Future> requests = [];
      // This is the function that will be executed every 1 minutes.
      // For example, you could modify the items list periodically.
      List<ResultRow> results = await mysqlClient.getRequests();
      for (ResultRow each in results) {
        int requestId = int.parse(each.toColumnMap()['id'].toString());
        int igId = int.parse(each.toColumnMap()['ig_id'].toString());
        String token = each.toColumnMap()['token'].toString();
        String igToken = each.toColumnMap()['ig_token'].toString();
        final urls = each.toColumnMap()['urls'];
        String caption = each.toColumnMap()['caption'].toString();
        String type = each.toColumnMap()['type'].toString();
        String status = each.toColumnMap()['status'].toString();
        ids.add(requestId);
        requests.add(network.globeSend({
          'ig_id': igId,
          'ut': token,
          'igt': igToken,
          'urls': urls,
          'caption': caption,
          'type': type,
        }));
      }
      List responses = await Future.wait(requests);
      final query = """
    UPDATE user_request_history
    SET status = sub.status, urls = @urls, ig_token = @ig_token, token = @token
    FROM (
      SELECT  unnest(ARRAY[${ids.map((id) => id.toString()).join(',')}])::INTEGER AS id,
       unnest(ARRAY[${responses.map((token) => "'$token'").join(',')}])::TEXT AS status
    ) AS sub
    WHERE user_request_history.id = sub.id;
  """;
      await mysqlClient.updateData(query: query, data: {
        'urls': [],
        'ig_token': '',
        'token': '',
      });
    });
  }
}
