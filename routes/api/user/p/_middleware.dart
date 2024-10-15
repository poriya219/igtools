import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../main.dart';

Handler middleware(Handler handler) {
  return (context) async {
    String userId = context.read();
    if (userId == null && userId.isEmpty) {
      return Response.json(
        statusCode: 500,
        body: 'user id not found!',
      );
    }
    Map user = await mysqlClient.getUserInfo(userId);
    bool hasPlan = bool.tryParse(user['has_plan'].toString()) ?? false;
    if (hasPlan) {
      try {
        final response = await handler(context);
        return response;
      } catch (e) {
        print('e: $e');
        return Response.json(
          body: e.toString(),
          statusCode: 500,
        );
      }
    }

    return Response.json(
      body: 'User has no plan',
      statusCode: HttpStatus.paymentRequired,
    );
  };
}
