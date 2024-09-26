import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:igtools/persistence.dart';
import 'package:dotenv/dotenv.dart';

final mysqlService = FrogMysqlClient();

Future<Response> onRequest(RequestContext context) async {
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

  await mysqlService.connect();

  // Check if user already exists
  final userExists = await mysqlService.userExists(email);
  print('userExists: $userExists');

  if (userExists) {
    await mysqlService.close(); // Close connection
    return Response.json(
      body: {'error': 'Username or email already exists.'},
      statusCode: HttpStatus.notAcceptable,
    );
  }

  // Create new user in the database
  final passwordHash = hashPassword(password);

  await mysqlService.insertUser(email, passwordHash);

  int id = await mysqlService.getUserID(email);
  var env = DotEnv(includePlatformEnvironment: true)..load();
  final String jwtSecret = env['JWT_SECRET']!;

  // Generate JWT token
  final jwt = JWT({'id': id});

  // Sign the token
  final token = jwt.sign(SecretKey(jwtSecret));

  await mysqlService.close(); // Close connection

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
