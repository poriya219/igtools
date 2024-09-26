// ignore_for_file: prefer_single_quotes

import 'package:mysql_client/mysql_client.dart';

class FrogMysqlClient {
  factory FrogMysqlClient() {
    return _inst;
  }
  FrogMysqlClient._internal() {
    print('internal');
    connect();
  }
  static final FrogMysqlClient _inst = FrogMysqlClient._internal();

  MySQLConnection? _connection;

  /// initialises a connection to database
  Future<void> connect() async {
    print('connect database');
    _connection = await MySQLConnection.createConnection(
      host: "127.0.0.1",
      port: 3306,
      userName: "root",
      password: "Po219219@",
      databaseName: "mysql",
    );
    await _connection?.connect();
  }

  Future<bool> userExists(String email) async {
    print(email);
    final result = await _connection!.execute(
      "SELECT * FROM users WHERE email = :email",
      {'email': email},
    );
    return result.numOfRows == 1; // If one user was found
  }

  Future<int> getUserID(String email) async {
    print(email);
    final result = await _connection!.execute(
      "select id,email from users where email like :email;",
      {'email': email},
    );
    return int.tryParse(result.rows.first.colByName('id').toString()) ??
        0; // If one user was found
  }

  Future<void> insertUser(String email, String passwordHash) async {
    await _connection!.execute(
      'INSERT INTO users (email, password, firstName, lastName) VALUES (:email, :password, :firstName, :lastName)',
      {
        'email': email,
        'password': passwordHash,
        'firstName': '',
        'lastName': '',
      },
    );
  }

  Future<void> close() async {
    await _connection!.close();
  }
}
