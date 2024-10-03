import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

import '../../../../main.dart';

Future<Response> onRequest(RequestContext context) async {
  // final st = await context.request.body();
  // final body = jsonDecode(st);
  // final price = body['price'].toString();
  // final name = body['name'].toString();
  // final description = body['description'].toString();
  // final duration = body['price'].toString();
  // await mysqlClient.connect();
  // await mysqlClient.addPlan(
  //     name: name, description: description, price: price, duration: duration);
  return Response.json(
    statusCode: 201,
  );
}
