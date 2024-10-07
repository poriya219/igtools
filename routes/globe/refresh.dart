import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
    );
  }
  final json = await context.request.json();
  String token = json['token'].toString();
  http.Response response = await http.get(
    Uri.parse(
        'https://graph.instagram.com/refresh_access_token?grant_type=ig_refresh_token&access_token=$token'),
  );
  return Response.json(
    statusCode: response.statusCode,
    body: response.body,
  );
}
