import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:igtools/env/env.dart';

final String jwtSecret = Env.secret;

Handler middleware(Handler handler) {
  return (context) async {
    final secretHeader = context.request.headers['Authorization'];
    if (secretHeader == null || secretHeader != jwtSecret) {
      return Response.json(
          statusCode: 403, body: 'Authorization Header is required');
    }
    final authHeader = context.request.headers['User'];
    // print('token: $authHeader');
    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      final token = authHeader.substring('Bearer '.length);

      try {
        final jwt = JWT.verify(token, SecretKey(jwtSecret));
        String tokenUSerId = jwt.payload['id'].toString();
        RequestContext f = context.provide(() => tokenUSerId.toString());
        final response = await handler(f);
        return response;
      } catch (e) {
        print('e: $e');
        return Response.json(
          body: 'Invalid token',
          statusCode: HttpStatus.forbidden,
        );
      }
    }

    return Response.json(
      body: 'User header is missing',
      statusCode: HttpStatus.unauthorized,
    );
  };
}
