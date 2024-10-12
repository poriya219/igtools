import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:igtools/network.dart';

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
  print('code: $code');
  if (code.isNotEmpty && code.isNotEmpty) {
    Network network = Network();
    http.Response response =
        await http.post(Uri.parse('${network.globeBase}/globe/change'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'code': code,
            }));
    print(response.statusCode);
    print(response.body);
    final sJson = jsonDecode(response.body);
    String token = sJson['access_token'].toString();
    String type = sJson['token_type'].toString();
    String finalToken = '$type $token';
    String id = sJson['user_id'].toString();
    int expireAt = int.parse(sJson['expires_in'].toString());
    DateTime ex = DateTime.now().add(Duration(seconds: expireAt));
    String expire = '${ex.year}-${ex.month}-${ex.day}';
    await mysqlClient.insertUserAccount(userId, '$finalToken#poqi#$id', expire);
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
