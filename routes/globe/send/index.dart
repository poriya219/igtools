import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method == HttpMethod.post) {
    final st = await context.request.body();
    final body = jsonDecode(st);

    String caption = body['caption'].toString();
    String type = body['type'].toString();
    String userID = body['ig_id'].toString();
    String igt = body['igt'].toString();
    final urls = body['urls'];
    String ut = body['ut'].toString();

    List<String> finalUrl = ['', ''];
    switch (type) {
      case 'Story':
        finalUrl = [
          'https://graph.instagram.com/v20.0/$userID/media?media_type=STORIES&access_token=$igt',
          'https://graph.instagram.com/v20.0/$userID/media_publish?media_type=STORIES&access_token=$igt',
        ];
        break;
      case 'SinglePost':
        finalUrl = [
          'https://graph.instagram.com/v20.0/$userID/media?access_token=$igt',
          'https://graph.instagram.com/v20.0/$userID/media_publish?access_token=$igt',
        ];
        break;
      case 'CarouselPost':
        finalUrl = [
          'https://graph.instagram.com/v20.0/$userID/media?access_token=$igt',
          'https://graph.instagram.com/v20.0/$userID/media_publish?access_token=$igt',
        ];
        break;
      case 'Reels':
        finalUrl = [
          'https://graph.instagram.com/v20.0/$userID/media?media_type=REELS&access_token=$igt',
          'https://graph.instagram.com/v20.0/$userID/media_publish?media_type=REELS&access_token=$igt',
        ];
        break;
      default:
        finalUrl = ['', ''];
        break;
    }

    String children = '';
    if (type == 'CarouselPost') {
      if (urls != null) {
        for (var each in urls as List) {
          http.Response response = await http.post(
            Uri.parse(finalUrl[0]),
            body: {'image_url': each.toString(), 'is_carousel_item': 'true'},
          );
          if (response.statusCode == 200) {
            final r = jsonDecode(response.body);
            String id = r['id'].toString();
            if (children.isEmpty) {
              children = id;
            } else {
              children = children + ',$id';
            }
          }
        }
      }
    }

    final response = await http.post(Uri.parse(finalUrl[0]),
        body: type != 'CarouselPost'
            ? {'image_url': urls[0].toString(), 'caption': caption}
            : {
                'children': children,
                'media_type': 'CAROUSEL',
                'caption': caption
              });
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

    // ignore: unawaited_futures
    http.delete(
      Uri.parse('https://igtoolspanel.ir/api/user/file'),
      headers: {
        'Authorization': 'OhyLPPlyynK8FraGgcHSKmIb9lgR1EKw',
        'User': ut,
      },
      body: {
        'urls': urls,
      },
    );

    return Response(
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}
