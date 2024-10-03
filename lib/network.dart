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

  Future createPayment({required String amount, required String hex}) async {
    http.Response response =
        await http.post(Uri.parse('https://gateway.zibal.ir/v1/request'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'merchant': 'zibal',
              'amount': int.parse(amount),
              'callbackUrl': 'http://localhost:8080/payment/result',
              'orderId': 'ZBL-$hex',
            }));
    print(response.statusCode);
    print(response.body);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json;
    } else {
      return {};
    }
  }
}
