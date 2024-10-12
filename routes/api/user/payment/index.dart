import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:igtools/network.dart';
import 'package:uuid/uuid.dart';

import '../../../../main.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(statusCode: HttpStatus.methodNotAllowed);
  }
  String userId = context.read();
  var uuid = Uuid();
  String uuidString = uuid.v1().toString();
  String hex = uuidString.substring(0, 6).split('-').last;
  Network network = Network();
  final st = await context.request.body();
  final body = jsonDecode(st);
  final id = body['id'].toString();
  Map plan = await mysqlClient.getPlanInfo(id);
  String amount = plan['price'].toString();
  final data = await network.createPayment(amount: amount, hex: hex);

  // In a real application, you would typically generate the payment URL dynamically
  // and possibly send a session token for security purposes.

  // Example: Redirecting to a Stripe Checkout session URL
  final trackId = data['trackId'];
  final status = data['result'];

  if (status == 100) {
    await mysqlClient.addPayment(
        user_id: userId,
        amount: amount,
        orderId: 'ZBL-$hex',
        planId: id,
        trackId: trackId.toString());

    return Response.json(
      statusCode: HttpStatus.ok,
      body: {
        'url': 'https://gateway.zibal.ir/start/${trackId.toString()}',
      },
    );
  }
  return Response.json(
    statusCode: 400,
    body: data['message'].toString(),
  );
  // Redirecting the user to the payment URL
}
