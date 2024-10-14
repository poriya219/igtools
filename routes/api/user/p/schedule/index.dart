import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../../../main.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    String userId = context.read<String>().toString();
    final st = await context.request.body();
    final body = jsonDecode(st);
    int index = int.tryParse(body['index'].toString()) ?? 0;
    Map igInfo = await mysqlClient.getIGAccountInfo(userId, index);
    String igToken = igInfo['token'].toString().split('bearer ').last;
    await mysqlClient.addUserRequest(
        userId: int.parse(userId),
        scheduledTime: body['time'].toString(),
        igId: int.parse(igInfo['id'].toString()),
        token: context.request.headers['User'].toString(),
        igToken: igToken,
        urls: body['urls'],
        caption: body['caption'].toString(),
        type: body['type'].toString(),
        status: 'pending');
    return Response.json(
      statusCode: 201,
      body: 'post scheduled successfully',
    );
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
