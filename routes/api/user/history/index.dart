import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../main.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.get) {
    String uid = context.read<String>().toString();
    final request = context.request;
    final params = request.uri.queryParameters;
    final index = params['index'] ?? '';

    if (uid.isNotEmpty && index.isNotEmpty) {
      Map data = await mysqlClient.getUserHistory(
        int.tryParse(uid) ?? 0,
        int.tryParse(index) ?? 0,
      );

      return Response.json(
        statusCode: 200,
        body: data,
      );
    } else {
      return Response.json(
          statusCode: HttpStatus.badRequest, body: 'index & uid is required!');
    }
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
