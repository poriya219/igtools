import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:igtools/models/ig_request.dart';

import '../../../lib/state_manager.dart';

Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;

  if (context.request.method == HttpMethod.post) {
    final body = await context.request.json();
    final item = IGRequest(
      token: body['token'].toString(),
      url: body['url'].toString(),
      time: body['time'].toString(),
      userID: body['id'].toString(),
    );

    StateManager().items.add(item);

    return Response(
      statusCode: 201,
      body: StateManager().items.toString(),
    );
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
