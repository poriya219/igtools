import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

import '../../../../../main.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
    );
  }
  String userId = context.read<String>().toString();
  final body = await context.request.json();
  String code = (body['code'] ?? '').toString();
  if (code.isNotEmpty && code.isNotEmpty) {
    http.Response response = await http.post(
        Uri.parse(
            'https://igtools-askr2yw-poriua219.globeapp.dev/globe/change'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'code': code,
        }));
    final sJson = jsonDecode(response.body);
    String token = sJson['access_token'].toString();
    String type = sJson['token_type'].toString();
    String finalToken = '$type $token';
    String id = sJson['user_id'].toString();
    await mysqlClient.connect();
    await mysqlClient.insertUserAccount(userId, '$finalToken#poqi#$id');
    return Response.json(
      statusCode: HttpStatus.created,
    );
  } else {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: 'token and id are required',
    );
  }
}
