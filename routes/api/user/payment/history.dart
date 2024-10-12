import 'dart:async';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

import '../../../../main.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(statusCode: HttpStatus.methodNotAllowed);
  }
  String userId = context.read();

  List history = await mysqlClient.getUserPayments(userId);

  return Response.json(
    statusCode: HttpStatus.ok,
    body: history,
  );
}
