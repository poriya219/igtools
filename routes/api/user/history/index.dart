import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../main.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.get) {
    String uid = context.read<String>().toString();
    final request = context.request;
    final params = request.uri.queryParameters;
    final userId = params['userId'] ?? '';

    if (uid.isNotEmpty) {
      await mysqlClient.connect();
      Map data = await mysqlClient.getUserHistory(
        int.tryParse(uid) ?? 0,
        userId,
      );

      return Response.json(
        statusCode: 200,
        body: data,
      );
    } else {
      return Response.json(
          statusCode: HttpStatus.badRequest, body: 'uid is required!');
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
