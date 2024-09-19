import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:hive/hive.dart';
import 'package:igtools/state_manager.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.get) {
    final request = context.request;
    final params = request.uri.queryParameters;
    final uid = params['uid'] ?? '';

    if (uid.isNotEmpty) {
      Hive.init('hive');
      var box = await Hive.openBox('history');
      Map map = box.toMap();
      Map userHistory = map[uid] != null ? map[uid] as Map : {};

      return Response(
        statusCode: 200,
        body: jsonEncode({
          'history': userHistory,
        }),
        // body: 'Request was set!',
      );
    } else {
      return Response(
          statusCode: HttpStatus.badRequest, body: 'uid is required!');
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
