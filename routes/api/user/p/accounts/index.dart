import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../../main.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
    );
  }
  String userId = context.read<String>().toString();
  await mysqlClient.connect();
  List data = await mysqlClient.getUserAccounts(userId);
  return Response.json(
    statusCode: 200,
    body: data,
  );
}
