import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class Network {
  String globeBase = 'https://igtools-fb7wuih-poriua219.globeapp.dev';
  Future getAccountDetail(String token) async {
    http.Response response = await http.get(
      Uri.parse('$globeBase/globe/user/info?token=$token'),
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

  Future refreshToken(String token) async {
    http.Response response =
        await http.post(Uri.parse('$globeBase/globe/refresh'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'token': token,
            }));
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
              'callbackUrl': 'https://igtoolspanel.ir/payment/result',
              'orderId': 'ZBL-$hex',
            }));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json;
    } else {
      return {};
    }
  }

  Future checkPayment(String trackId) async {
    final response = await http.post(
      Uri.parse('https://gateway.zibal.ir/v1/verify'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({"merchant": "zibal", "trackId": trackId}),
    );
    print('status code: ${response.statusCode}');
    print(response.body);
    final json = jsonDecode(response.body);
    return json;
  }

  Future<void> sendPasswordResetEmail(String email, String resetLink) async {
    final smtpServer = SmtpServer(
      'smtp.c1.liara.email',
      port: 587,
      username: 'upbeat_neumann_4cvtql',
      password: 'a655aa09-0eeb-4ea4-b692-9f5d7865c94e',
    ); // Configure your SMTP server settings here

    final message = Message()
      ..from = Address('support@igtoolspanel.ir', 'IGTools')
      ..recipients.add(email)
      ..subject = 'Password Reset Request'
      ..text = 'Click this link to reset your password: \n $resetLink';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } catch (e) {
      print('Message not sent. Error: $e');
    }
  }

  Future<int> globeSend(Map body) async {
    http.Response response = await http.post(Uri.parse('$globeBase/globe/send'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body));
    print('send request results:');
    print('status: ${response.statusCode}');
    print('body: ${response.body}');
    return response.statusCode;
  }
}

// WD9CF0vloxWIiBzC7eLtORHj36OTlpLV