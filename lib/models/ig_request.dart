import 'dart:convert';

class IGRequest {
  final String token;
  final String url;
  final String time;
  final String userID;
  final String uid;
  final String hex;
  final String type;
  final Map? data;

  IGRequest(
      {required this.token,
      required this.url,
      required this.time,
      required this.uid,
      required this.hex,
      required this.type,
      this.data,
      required this.userID});

  @override
  String toString() {
    Map map = {
      'token': token,
      'url': url,
      'time': time,
      'uid': uid,
      'userID': userID,
      'hex': hex,
      'type': type,
      'data': data,
    };
    String json = jsonEncode(map);
    return json;
  }

  static IGRequest fromString(String data) {
    final map = jsonDecode(data);
    return IGRequest(
        token: map['token'].toString(),
        url: map['url'].toString(),
        time: map['time'].toString(),
        uid: map['uid'].toString(),
        hex: map['hex'].toString(),
        type: map['type'].toString(),
        data: map['data'] != null ? map['data'] as Map : {},
        userID: map['userID'].toString());
  }

  static Map toMap(IGRequest data) {
    return {
      'token': data.token,
      'url': data.url,
      'time': data.time,
      'id': data.userID,
      'uid': data.uid,
      'hex': data.hex,
      'type': data.type,
      'data': data.data,
    };
  }
}
