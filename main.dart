import 'dart:async';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:igtools/persistence.dart';
import 'package:igtools/state_manager.dart';

Future<void> main() async {
  // await serve(router, 'localhost', 8080);
  // Any additional setup code can go here.
}

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  // print('load main');
  print('version: 1.0.1');
  StateManager();
  // 1. Execute any custom code prior to starting the server...

  // 2. Use the provided `handler`, `ip`, and `port` to create a custom `HttpServer`.
  // Or use the Dart Frog serve method to do that for you.
  return serve(handler.use(databaseHandler()), ip, port);
}

final mysqlClient = FrogMysqlClient();

Middleware databaseHandler() {
  return (handler) {
    return handler.use(
      provider<FrogMysqlClient>(
        (context) => mysqlClient,
      ),
    );
  };
}
