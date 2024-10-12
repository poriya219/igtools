import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../main.dart';

FutureOr<Response> onRequest(RequestContext context) async {
  String userId = context.read<String>().toString();
  if (context.request.method != HttpMethod.get) {
    return Response(
      statusCode: HttpStatus.methodNotAllowed,
    );
  }
  try {
    List data = await mysqlClient.getPaymentPlans();
    return Response.json(statusCode: 200, body: data);
  } catch (e) {
    return Response(
      statusCode: HttpStatus.badGateway,
    );
  }
}
