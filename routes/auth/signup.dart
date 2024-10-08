import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:igtools/env/env.dart';

import '../../main.dart';

Future<Response> onRequest(RequestContext context) async {
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

  // Check if user already exists
  int? userExists = await mysqlClient.userExists(email);
  print('userExists: $userExists');

  if (userExists != null) {
    await mysqlClient.close(); // Close connection
    return Response.json(
      body: {'error': 'Username or email already exists.'},
      statusCode: HttpStatus.notAcceptable,
    );
  }

  // Create new user in the database
  final passwordHash = hashPassword(password);

  await mysqlClient.insertUser(email, passwordHash);

  int id = await mysqlClient.getUserID(email);

  // Generate JWT token
  final jwt = JWT({'id': id});

  // Sign the token
  final token = jwt.sign(SecretKey(jwtSecret));

  await mysqlClient.close(); // Close connection

  return Response.json(
    body: {
      'token': token,
    },
    statusCode: 201,
  );
}

String hashPassword(String password) {
  final bytes = utf8.encode(password); // convert to utf8
  final digest = sha256.convert(bytes);
  return digest.toString(); // store the hash
}
