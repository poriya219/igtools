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
      type: body['type'].toString(),
      data: body['data'] != null ? body['data'] as Map : {},
    );
    String caption =
        item.data?['caption'] != null ? item.data!['caption'].toString() : '';
    List<String> finalUrl = ['', ''];
    switch (item.type) {
      case 'Story':
        finalUrl = [
          'https://graph.instagram.com/v20.0/${item.userID}/media?media_type=STORIES&access_token=${item.token}',
          'https://graph.instagram.com/v20.0/${item.userID}/media_publish?media_type=STORIES&access_token=${item.token}',
        ];
        break;
      case 'SinglePost':
        finalUrl = [
          'https://graph.instagram.com/v20.0/${item.userID}/media?access_token=${item.token}',
          'https://graph.instagram.com/v20.0/${item.userID}/media_publish?access_token=${item.token}',
        ];
        break;
      case 'CarouselPost':
        finalUrl = [
          'https://graph.instagram.com/v20.0/${item.userID}/media?media_type=STORIES&access_token=${item.token}',
          'https://graph.instagram.com/v20.0/${item.userID}/media_publish?media_type=STORIES&access_token=${item.token}',
        ];
        break;
      case 'Reels':
        finalUrl = [
          'https://graph.instagram.com/v20.0/${item.userID}/media?media_type=REELS&access_token=${item.token}',
          'https://graph.instagram.com/v20.0/${item.userID}/media_publish?media_type=REELS&access_token=${item.token}',
        ];
        break;
      default:
        finalUrl = ['', ''];
        break;
    }

    print('send request');
    http.Response response = await http.post(Uri.parse(finalUrl[0]),
        body: {'image_url': item.url, 'caption': caption});
    if (response.statusCode == 200) {
      final r = jsonDecode(response.body);
      String id = r['id'].toString();
      if (id.isNotEmpty && id != 'null') {
        http.Response response2 =
            await http.post(Uri.parse(finalUrl[1]), body: {
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
