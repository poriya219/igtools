import 'dart:convert';

class IGRequest {
  final String token;
  final String url;
  final String time;
  final String userID;
  final String uid;
  final String hex;

  IGRequest(
      {required this.token,
      required this.url,
      required this.time,
      required this.uid,
      required this.hex,
      required this.userID});

  @override
  String toString() {
    Map data = {
      'token': token,
      'url': url,
      'time': time,
      'uid': uid,
      'userID': userID,
      'hex': hex,
    };
    String json = jsonEncode(data);
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
    };
  }
}
