import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:igtools/models/ig_request.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    final st = await context.request.body();
    final body = jsonDecode(st);
    final item = IGRequest(
      token: body['token'].toString(),
      url: body['url'].toString(),
      time: body['time'].toString(),
      userID: body['id'].toString(),
      uid: body['uid'].toString(),
      hex: body['hex'].toString(),
    );

    print('send request');
    http.Response response = await http.post(
        Uri.parse(
            'https://graph.instagram.com/v20.0/${item.userID}/media?media_type=STORIES&access_token=${item.token}'),
        body: {'image_url': item.url});
    if (response.statusCode == 200) {
      final r = jsonDecode(response.body);
      String id = r['id'].toString();
      if (id.isNotEmpty && id != 'null') {
        http.Response response2 = await http.post(
            Uri.parse(
                'https://graph.instagram.com/v20.0/${item.userID}/media_publish?media_type=STORIES&access_token=${item.token}'),
            body: {
              'creation_id': id,
            });
        return Response(
          statusCode: response2.statusCode,
          body: response2.body,
        );
      }
    }

    return Response(
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
