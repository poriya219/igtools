import 'dart:convert';

import 'package:http/http.dart' as http;

class Network {
  Future getAccountDetail(String token) async {
    http.Response response = await http.get(
      Uri.parse(
          'https://igtools-askr2yw-poriua219.globeapp.dev/globe/user/info?token=$token'),
      headers: {
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json;
    } else {
      return {};
    }
  }
}
