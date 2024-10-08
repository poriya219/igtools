import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

import '../../../main.dart';

FutureOr<Response> onRequest(RequestContext context) async {
  print('0');
  String userId = context.read<String>().toString();
  print('1');
  if (context.request.method != HttpMethod.post) {
    return Response(
      statusCode: HttpStatus.methodNotAllowed,
    );
  }
  print('2');
  final b = await context.request.json();
  print(b.runtimeType);
  if (b.runtimeType.toString() == '_Map<String, dynamic>') {
    Map body = b as Map;
    if (body.keys.isNotEmpty) {
      List<String> keys = [
        'firstname',
        'lastname',
        'image',
      ];
      String q = '';
      Map<String, dynamic> d = {};
      for (String each in List.from(body.keys.toList())) {
        print(keys);
        if (keys.contains(each)) {
          q = '$q$each = @$each,';
          d[each] = body[each];
        } else {
          return badResponse();
        }
      }
      if (q.isNotEmpty) {
        if (q.endsWith(',')) {
          q = q.substring(0, q.length - 1);
        }
        d['id'] = userId;
        String query = 'UPDATE users SET $q WHERE id = @id';
        await mysqlClient.updateData(query: query, data: d);
        return Response.json(statusCode: 200, body: 'Changed successfully');
      }
    }
    return badResponse();
  }
  print('not map');
  return badResponse();
}

Response badResponse() {
  return Response.json(
    statusCode: HttpStatus.badRequest,
    body: 'body is required',
  );
}
