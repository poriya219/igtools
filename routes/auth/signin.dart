import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:igtools/env/env.dart';

import '../../main.dart';

FutureOr<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
    );
  }
  final header = context.request.headers;
  String secret = header['Authorization'] ?? '';
  final String jwtSecret = Env.secret;
  if (secret.isEmpty || secret != jwtSecret) {
    return Response.json(
      body: 'Authorization is required',
      statusCode: 403,
    );
  }
  final body = await context.request.json();

  final email = body['email'] as String?;
  final password = body['password'] as String?;

  // Basic validations
  if (email == null || password == null) {
    return Response.json(
      body: {'error': 'Please provide username, email, and password.'},
      statusCode: 400,
    );
  }

  await mysqlClient.connect();

  // Check if user already exists
  final userExists = await mysqlClient.userExists(email);

  if (userExists) {
    final passwordHash = hashPassword(password);
    final bool login = await mysqlClient.checkLogin(email, passwordHash);
    if (login) {
      int id = await mysqlClient.getUserID(email);

      // Generate JWT token
      final jwt = JWT({'id': id});

      // Sign the token
      final token = jwt.sign(SecretKey(jwtSecret));

      return Response.json(
        body: {
          'token': token,
        },
      );
    } else {
      return Response.json(
        body: 'password is incorrect',
        statusCode: HttpStatus.notAcceptable,
      );
    }
  } else {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: 'User not found',
    );
  }
}

String hashPassword(String password) {
  final bytes = utf8.encode(password); // convert to utf8
  final digest = sha256.convert(bytes);
  return digest.toString(); // store the hash
}
