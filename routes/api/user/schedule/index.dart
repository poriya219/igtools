import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:igtools/models/ig_request.dart';
import 'package:igtools/state_manager.dart';
import 'package:uuid/uuid.dart';

import '../../../../main.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    String userId = context.read<String>().toString();
    String d = context.read();
    await mysqlClient.connect();
    final st = await context.request.body();
    final body = jsonDecode(st);
    int index = int.tryParse(body['index'].toString()) ?? 0;
    Map igInfo = await mysqlClient.getIGAccountInfo(userId, index);
    var uuid = Uuid();
    String uuidString = uuid.v1().toString();
    String hex = uuidString.substring(0, 6).split('-').last;
    final item = IGRequest(
      token: igInfo['token'].toString(),
      url: body['url'].toString(),
      time: body['time'].toString(),
      userID: igInfo['id'].toString(),
      hex: hex,
      uid: userId,
      type: body['type'].toString(),
      data: body['data'] != null ? body['data'] as Map : {},
    );

    StateManager().items.add(item);
    String query =
        'INSERT INTO user_request_history (user_id, request_date, request_type, status, hex, account_id) VALUES (@userId, NOW(), @requestType, @status, @hex, @account_id)';
    await mysqlClient.connect();
    await mysqlClient.updateData(query: query, data: {
      'userId': int.tryParse(userId) ?? 0,
      'requestType': item.type,
      'status': '0',
      'hex': item.hex,
      'account_id': item.userID,
    });
    return Response(
      statusCode: 201,
      body: StateManager().items.toString(),
      // body: 'Request was set!',
    );
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
