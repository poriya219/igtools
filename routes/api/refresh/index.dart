import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:igtools/models/ig_request.dart';

Future<Response> onRequest(RequestContext context) async {
  Hive.init('hive');
  var box = await Hive.openBox('tasks');
  Map map = box.toMap();
  print('map: $map');
  for (var each in map.keys.toList()) {
    String timeString = each.toString();
    print(timeString);
    DateTime time = DateTime.parse(timeString);
    DateTime now = DateTime.now();
    if (time.difference(now).inMinutes == 0) {
      print('send request');
      String v = map[each].toString();
      IGRequest item = IGRequest.fromString(v);
      http.Response response = await http.post(
          Uri.parse(
              'https://graph.instagram.com/v20.0/${item.userID}/media?media_type=STORIES&access_token=${item.token}'),
          body: {'image_url': item.url});
      print('status 1: ${response.statusCode}');
      if (response.statusCode == 200) {
        final r = jsonDecode(response.body);
        String id = r['id'].toString();
        if (id.isNotEmpty && id != 'null') {
          http.Response response2 = await http.post(
              Uri.parse(
                  'https://graph.instagram.com/v20.0/${item.userID}/media_publish?media_type=STORIES&access_token=${item.token}'),
              body: {
                'creation_id': id,
              });
          print('status 2: ${response2.statusCode}');
        }
      }
      await box.delete(each);
    }
    if (time.isBefore(now)) {
      await box.delete(each);
    }
  }

  return Response(
    statusCode: 200,
    body:
        'Successfully get task list at ${DateTime.now()}. length: ${map.keys.length}',
  );

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
