import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:igtools/network.dart';

import '../../main.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.get) {
    final request = context.request;
    final params = request.uri.queryParameters;
    final challenge = params['hub.challenge'];
    String verifyToken = params['hub.verify_token'] ?? '';
    if (verifyToken == 'WD9CF0vloxWIiBzC7eLtORHj36OTlpLV') {
      print('200');
      return Response(
        statusCode: 200,
        body: challenge,
      );
    } else {
      print('403');
      return Response(
        statusCode: 403,
        body: challenge,
      );
    }
  }
  if (context.request.method == HttpMethod.post) {
    final json = await context.request.json();
    print('webhook body: $json');
    final entry = json['entry'] ?? [];
    if (entry != null && entry != []) {
      final map = entry[0];
      final changes = map['changes'] ?? [];
      final finalMap = changes[0] ?? {};
      String field = finalMap['field'].toString();
      if (field == 'comments') {
        final value = finalMap['value'] ?? {};
        final from = value['from'] ?? {};
        String fromId = from['id'].toString();
        String accountId = map['id'].toString();
        if (fromId != accountId) {
          String commentId = value['id'].toString();
          String igt = await mysqlClient.getIgToken(accountId);
          Network network = Network();
          int status = await network.replyToComment(commentId, igt);
          print('reply comment status: $status');
        }
      }
    }
    return Response(
      statusCode: 200,
    );
  }

  return Response(
    statusCode: HttpStatus.methodNotAllowed,
  );
}
