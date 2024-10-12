import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_frog/dart_frog.dart';
import 'package:image_compression/image_compression.dart';
import 'package:minio/minio.dart';
import 'package:uuid/uuid.dart';

Future<Response> onRequest(RequestContext context) async {
  // Check if it's a POST request
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  String uid = context.read<String>().toString();

  // Read the request body as bytes
  bool isJson = context.request.headers['Content-Type'] == 'application/json';
  final json = await context.request.formData();
  print('json: ${json.files}');

  if (json.files['file'] == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: "'file' is required",
    );
  }
  bool compress = bool.tryParse(json.fields['compress'].toString()) ?? false;
  bool isProfile = bool.tryParse(json.fields['is_profile'].toString()) ?? false;
  UploadedFile? uploadedFile = json.files['file'] as UploadedFile;
  String name = uploadedFile.name;
  String fileType = name.split('.').last;
  List<int> bytes = await uploadedFile.readAsBytes();
  Uint8List bodyBytes = Uint8List.fromList(bytes);
  print('compress: $compress');
  if (compress == true) {
    print('compressing');
    bodyBytes = await compressImage(file: bodyBytes);
  }

  // Here you might want to extract the filename and content type
  var uuid = Uuid();
  String uuidString = uuid.v1().toString();
  String fileName = uuidString.substring(0, 6).split('-').last;

  final minio = Minio(
    endPoint: 'storage.c2.liara.space',
    region: 'us-east-1',
    accessKey: 'mooibb54qa0mu24a',
    secretKey: 'f7ba1376-a0ab-46cf-bd50-9367365e2861',
  );

  try {
    String result = await minio.putObject(
      'igtools',
      isProfile
          ? 'profiles/$fileName.$fileType'
          : 'uploads/$uid/$fileName.$fileType',
      Stream<Uint8List>.value(bodyBytes),
      onProgress: (bytes) => print('$bytes uploaded'),
    );

    String fileUrl = isProfile
        ? 'https://storage.c2.liara.space/igtools/profiles/$fileName.$fileType'
        : 'https://storage.c2.liara.space/igtools/uploads/$uid/$fileName.$fileType';

    return Response.json(body: {
      'message': 'File uploaded successfully!',
      'url': fileUrl,
    }, statusCode: 201);
  } catch (e) {
    print(e);
    return Response.json(
        body: {'message': 'Error: $e'},
        statusCode: HttpStatus.internalServerError);
  }
}

Future<Uint8List> compressImage({required Uint8List file}) async {
  try {
    final input = ImageFile(
      rawBytes: file,
      filePath: '/',
    );
    final output = await compressInQueue(ImageFileConfiguration(input: input));
    print('output size: ${output.sizeInBytes}');
    return output.rawBytes;
  } catch (e) {
    print('error in compress: $e');
    return Uint8List(0);
  }
}
