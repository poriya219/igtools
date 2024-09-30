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
  String code = json['code'].toString();
  final String appId = '860424852858465';
  final String appSecret = '109f4395a9b6001bfa510ad2f2256834';
  http.Response response = await http.post(
    Uri.parse('https://api.instagram.com/oauth/access_token'),
    body: {
      'client_id': appId,
      'client_secret': appSecret,
      'grant_type': 'authorization_code',
      'redirect_uri': 'https://poriya219.github.io/',
      'code': code,
    },
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    String at = data['access_token'].toString();
    String ui = data['user_id'].toString();
    final secondResponse = await http.get(Uri.parse(
        "https://graph.instagram.com/access_token?grant_type=ig_exchange_token &client_secret=$appSecret &access_token=$at"));
    if (secondResponse.statusCode == 200) {
      final secondData = jsonDecode(secondResponse.body);
      String accessToken = secondData['access_token'].toString();
      String tokenType = secondData['token_type'].toString();
      int expiresIn = int.tryParse(secondData['expires_in'].toString()) ?? 0;
      Map temp = {
        'access_token': accessToken,
        'token_type': tokenType,
        'user_id': ui,
        'expires_in': expiresIn,
      };
      return Response.json(
        statusCode: 200,
        body: temp,
      );
    } else {
      return Response(
          statusCode: secondResponse.statusCode, body: secondResponse.body);
    }
  } else {
    return Response.json(
      statusCode: response.statusCode,
      body: response.body,
    );
  }
}
