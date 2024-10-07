import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  // Serve the Flutter web app's index.html file
  final filePath = 'public/index.html';
  return Response(
    body: await File(filePath).readAsString(),
    headers: {
      HttpHeaders.contentTypeHeader: 'text/html',
    },
  );
}
