import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:minio/minio.dart';

Future<Response> onRequest(RequestContext context) async {
  String uid = context.read<String>().toString();
  if (context.request.method == HttpMethod.delete) {
    final json = await context.request.json();
    final urls = json['urls'] ?? [];
    List urlsList = urls as List;
    List<String> finalList = [];
    for (var each in urlsList) {
      finalList
          .add(each.toString().split('igtools.storage.c2.liara.space/').last);
    }
    final minio = Minio(
      endPoint: 'storage.c2.liara.space',
      region: 'us-east-1',
      accessKey: 'mooibb54qa0mu24a',
      secretKey: 'f7ba1376-a0ab-46cf-bd50-9367365e2861',
    );

    try {
      await minio.removeObjects('igtools', finalList);

      return Response.json(body: {
        'message': 'Files deleted successfully!',
      }, statusCode: 200);
    } catch (e) {
      print(e);
      return Response.json(
          body: {'message': 'Error: $e'},
          statusCode: HttpStatus.internalServerError);
    }
  } else {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
}
