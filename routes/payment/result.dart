import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:igtools/network.dart';
import 'package:igtools/persistence.dart';

Future<Response> onRequest(RequestContext context) async {
  final request = context.request;
  final params = request.uri.queryParameters;
  final trackId = params['trackId'] ?? '';
  Network network = Network();
  final json = await network.checkPayment(trackId);
  final orderId = json['orderId'] ?? '';
  final status = json['status'] ?? '';
  String query =
      'UPDATE user_purchase_history SET status = @status WHERE order_id = @orderId';
  final mysqlClient = FrogMysqlClient();
  await mysqlClient.connect();
  await mysqlClient.updateData(query: query, data: {
    'status': status,
    'orderId': orderId,
  });
  List<int> errors = [-2, -1, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
  String message = !errors.contains(int.tryParse(status.toString()) ?? -2)
      ? 'موفق'
      : errors.contains(int.tryParse(status.toString()) ?? -2)
          ? 'ناموفق'
          : 'نامشخص';
  if (!errors.contains(int.tryParse(status.toString()) ?? -2)) {
    Map paymentInfo = await mysqlClient.getPaymentInfo(orderId.toString());
    String plan_id = paymentInfo['plan_id'].toString();
    String user_id = paymentInfo['user_id'].toString();
    if (plan_id.isNotEmpty && plan_id.toLowerCase() != 'null') {
      await mysqlClient.setUserPlan(planId: plan_id, userId: user_id);
    }
  }
  String sMessage = 'وضعیت پرداخت: $message';
  String tMessage = '$trackId :کد رهگیری';
  String oMessage = '$orderId :شناسه پرداخت';
  // Here is the HTML content that will be served
  final htmlContent = '''
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Result</title>
    <style>
      body {
        font-family: Arial, sans-serif;
        text-align: center;
        margin-top: 50px;
      }
      *{
 box-sizing:border-box;
}

.mybutton{
 background-color:#2196F3;
 width: 100%;
 border:none;
 border-radius:7px;
 color:#fff;
 padding:10px 25px;
 text-align:center;
 font-size:16px;
 cursor:pointer;
 transition:0.7s;
 margin-bottom:10px;
 display:block;
 text-decoration:none;
}

.mybutton:hover{
 background-color:#555;
 border-radius:15px;
}
    </style>
  </head>
  <body>
    <h1>$sMessage</h1>
    <p>$tMessage</p>
    <p>$oMessage</p>
    <a href="https://igtoolspanel.ir/payment/callback/" class="mybutton">بازگشت به برنامه</a>
  </body>
  </html>
  ''';

  return Response(
    body: htmlContent,
    headers: {
      HttpHeaders.contentTypeHeader: 'text/html',
    },
  );
}
