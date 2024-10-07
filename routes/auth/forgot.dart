import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:uuid/uuid.dart';

import '../../main.dart';

final uuid = Uuid();

Future<Response> onRequest(RequestContext context) async {
  // if (context.request.method == HttpMethod.post) {
  //   final body = await context.request.json();
  //   final email = body['email'].toString();

  //   if (email.toLowerCase() == 'null' || email.isEmpty) {
  //     return Response.json(
  //       body: {'message': 'Email is required'},
  //       statusCode: HttpStatus.badRequest,
  //     );
  //   }

  //   // Step 1: Check if the email exists in the database
  //   await mysqlClient.connect();
  //   final user = await mysqlClient.userExists(
  //       email); // Implement this function in your database helper

  //   if (user == false) {
  //     return Response.json(
  //       body: {'message': 'Email not found'},
  //       statusCode: HttpStatus.notFound,
  //     );
  //   }

  //   // Step 2: Generate a password reset token
  //   final token = uuid.v4(); // Generates a new unique token

  //   // Step 3: Save the token to the database with an expiration time
  //   await mysqlClient.savePasswordResetToken(
  //       user.id, token); // Implement this function to save token

  //   // Step 4: Send the email with the reset link
  //   final resetLink =
  //       'https://your-frontend-url.com/reset-password?token=$token';
  //   await sendPasswordResetEmail(
  //       email, resetLink); // Implement this function in your email service

  //   return Response.json(
  //     body: {'message': 'Password reset link has been sent to your email'},
  //     statusCode: HttpStatus.ok,
  //   );
  // }

  return Response.json(
    body: {'message': 'Method not allowed'},
    statusCode: HttpStatus.methodNotAllowed,
  );
}
