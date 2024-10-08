import 'dart:async';
import 'dart:convert';

import 'package:igtools/network.dart';
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
        await mysqlClient.resetPlans();
        List<Map> expiredTokens = await mysqlClient.getExpiredTokens();
        List<Future> requests = [];
        Network network = Network();
        List<int> ids = [];
        List<String> accountIds = [];
        for (Map each in expiredTokens) {
          String token = each['string'].toString().split('#poqi#').first;
          String accountId = each['string'].toString().split('#poqi#').last;
          String id = each['id'].toString();
          ids.add(int.tryParse(id) ?? 0);
          accountIds.add(accountId);
          requests.add(network.refreshToken(token));
        }
        List responses = await Future.wait(requests);
        List<String> newTokens = [];
        List<String> expireDates = [];
        for (var each in responses) {
          Map map = jsonDecode(each.toString()) as Map;
          String token = map['access_token'].toString();
          String type = map['token_type'].toString();
          String finalToken = '$type $token';
          int expireAt = int.tryParse(map['expires_in'].toString()) ?? 0;
          DateTime ex = DateTime.now().add(Duration(seconds: expireAt));
          String expireString = '${ex.year}-${ex.month}-${ex.day}';
          int index = responses.indexOf(each);
          newTokens.add('$finalToken#poqi#${accountIds[index]}');
          expireDates.add(expireString);
        }
        final query = """
    UPDATE user_strings
    SET string_value = sub.new_token, expire_at = sub.expire
    FROM (
      SELECT  unnest(ARRAY[${ids.map((id) => id.toString()).join(',')}])::INTEGER AS id,
       unnest(ARRAY[${newTokens.map((token) => "'$token'").join(',')}])::TEXT AS new_token,
       unnest(ARRAY[${expireDates.map((token) => "'$token'").join(',')}])::TEXT AS expire
    ) AS sub
    WHERE user_strings.id = sub.id;
  """;
        await mysqlClient.updateData(query: query, data: {});
      }
    });
  }
}
