import 'dart:async';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

import '../../main.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    final body = await context.request.json();
    final token = body['token'] as String?;
    final newPassword = body['newPassword'] as String?;

    // Validate inputs
    if (token == null ||
        token.isEmpty ||
        newPassword == null ||
        newPassword.isEmpty) {
      return Response.json(
        body: {'message': 'Token and new password are required'},
        statusCode: HttpStatus.badRequest,
      );
    }

    // Step 1: Validate the token
    final resetToken =
        await mysqlClient.findResetToken(token); // Implement this function
    if (resetToken == null) {
      return Response.json(
        body: {'message': 'Invalid token'},
        statusCode: HttpStatus.badRequest,
      );
    }
    bool isBefore = DateTime.parse(resetToken['expires_at'].toString())
        .isBefore(DateTime.now());
    if (isBefore) {
      return Response.json(
        body: {'message': 'Expired token'},
        statusCode: HttpStatus.badRequest,
      );
    }

    // Step 2: Update the user's password
    await mysqlClient.updateUserPassword(
        int.parse(resetToken['user_id'].toString()),
        newPassword); // Implement this function

    // Step 3: Remove or invalidate the token
    await mysqlClient.invalidateResetToken(token); // Implement this function

    return Response.json(
      body: {'message': 'Password has been reset successfully'},
      statusCode: HttpStatus.ok,
    );
  }

  return Response.json(
    body: {'message': 'Method not allowed'},
    statusCode: HttpStatus.methodNotAllowed,
  );
}
