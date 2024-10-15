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

    List<String> finalUrl = [
      'https://graph.instagram.com/v20.0/$userID/media?access_token=$igt',
      'https://graph.instagram.com/v20.0/$userID/media_publish?access_token=$igt',
    ];

    String children = '';
    if (type == 'CarouselPost') {
      if (urls != null) {
        for (var each in urls as List) {
          Map temp = {
            'is_carousel_item': 'true',
          };
          temp.addAll(getMediaBodies(each.toString()));
          http.Response response = await http.post(
            Uri.parse(finalUrl[0]),
            body: temp,
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

    final Map requestBody = {'caption': caption};
    requestBody.addAll(getPostType(type));
    if (type != 'CarouselPost') {
      requestBody.addAll(getMediaBodies(urls[0].toString()));
    }
    if (type == 'CarouselPost') {
      requestBody['children'] = children;
    }
    final response = await http.post(Uri.parse(finalUrl[0]), body: requestBody);
    if (response.statusCode == 200) {
      final r = jsonDecode(response.body);
      String id = r['id'].toString();
      if (id.isNotEmpty && id != 'null') {
        http.Response response2 =
            await http.post(Uri.parse(finalUrl[1]), body: {
          'creation_id': id,
        });
        // ignore: unawaited_futures
        http.delete(
          Uri.parse('https://igtoolspanel.ir/api/user/file'),
          headers: {
            'Authorization': 'OhyLPPlyynK8FraGgcHSKmIb9lgR1EKw',
            'User': ut,
          },
          body: jsonEncode({
            'urls': urls,
          }),
        );
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
      body: jsonEncode({
        'urls': urls,
      }),
    );

    return Response(
      statusCode: response.statusCode,
      body: response.body,
    );
  }

  return Response(statusCode: HttpStatus.methodNotAllowed);
}

Map getPostType(String type) {
  switch (type) {
    case 'Story':
      return {
        'media_type': 'STORIES',
      };
    case 'SinglePost':
      return {};
    case 'CarouselPost':
      return {
        'media_type': 'CAROUSEL',
      };
    case 'Reels':
      return {
        'media_type': 'REELS',
      };
    default:
      return {};
  }
}

Map getMediaBodies(String url) {
  final String? extension = url.split('.').last.toLowerCase();
  const videoExtensions = ['mp4', 'avi', 'mov', 'mkv', 'flv', 'wmv', 'webm'];
  bool isVideo = videoExtensions.contains(extension);
  switch (isVideo) {
    case true:
      return {
        'image_url': url,
      };
    case false:
      return {
        'video_url': url,
        'media_type': 'VIDEO',
      };
  }
}
