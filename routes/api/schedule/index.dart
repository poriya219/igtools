import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:hive/hive.dart';
import 'package:igtools/models/ig_request.dart';
import 'package:igtools/state_manager.dart';
import 'package:uuid/uuid.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    final st = await context.request.body();
    final body = jsonDecode(st);
    var uuid = Uuid();
    String uuidString = uuid.v1().toString();
    String hex = uuidString.substring(0, 6).split('-').last;
    final item = IGRequest(
      token: body['token'].toString(),
      url: body['url'].toString(),
      time: body['time'].toString(),
      userID: body['id'].toString(),
      hex: hex,
      uid: body['uid'].toString(),
      type: body['type'].toString(),
      data: body['data'] != null ? body['data'] as Map : {},
    );

    // Hive.init('hive');
    // var box = await Hive.openBox('tasks');

    // print('adding ${item.toString()}');
    // await box.put(item.time, item.toString());

    StateManager().items.add(item);
    Hive.init('hive');
    var box = await Hive.openBox('history');
    Map map = box.toMap();
    Map userHistory = map[item.uid] != null ? map[item.uid] as Map : {};

    userHistory[item.hex] = {
      'status': 0,
      'time': item.time,
      'type': item.type,
    };
    await box.put(item.uid, userHistory);
    return Response(
      statusCode: 201,
      body: StateManager().items.toString(),
      // body: 'Request was set!',
    );
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
