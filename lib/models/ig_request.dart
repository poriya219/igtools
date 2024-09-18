import 'dart:convert';

class IGRequest {
  final String token;
  final String url;
  final String time;
  final String userID;

  IGRequest(
      {required this.token,
      required this.url,
      required this.time,
      required this.userID});

  @override
  String toString() {
    Map data = {
      'token': token,
      'url': url,
      'time': time,
      'userID': userID,
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
        userID: map['userID'].toString());
  }
}
