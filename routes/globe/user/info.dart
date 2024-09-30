import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
    );
  }
  final request = context.request;
  final params = request.uri.queryParameters;
  final token = params['token'] ?? '';
  http.Response response = await http.get(
    Uri.parse(
        "https://graph.instagram.com/v20.0/me?fields=user_id,username,profile_picture_url,followers_count,follows_count,media_count&access_token=$token"),
  );
  return Response.json(statusCode: response.statusCode, body: response.body);
}
