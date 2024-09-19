import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:igtools/models/ig_request.dart';
import 'package:igtools/state_manager.dart';

Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;

  if (context.request.method == HttpMethod.post) {
    final st = await context.request.body();
    final body = jsonDecode(st);
    final item = IGRequest(
      token: body['token'].toString(),
      url: body['url'].toString(),
      time: body['time'].toString(),
      userID: body['id'].toString(),
    );

    // Hive.init('hive');
    // var box = await Hive.openBox('tasks');

    // print('adding ${item.toString()}');
    // await box.put(item.time, item.toString());

    StateManager().items.add(item);
    return Response(
      statusCode: 201,
      body: StateManager().items.toString(),
      // body: 'Request was set!',
    );
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
