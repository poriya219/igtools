import 'dart:convert';

import 'package:igtools/network.dart';
import 'package:postgres/postgres.dart';

class FrogMysqlClient {
  factory FrogMysqlClient() {
    return _inst;
  }
  FrogMysqlClient._internal() {
    print('internal');
    connect();
  }
  static final FrogMysqlClient _inst = FrogMysqlClient._internal();

  Connection? _connection;

  /// initialises a connection to database
  Future<void> connect() async {
    print('connect database');
    _connection = await Connection.open(
        Endpoint(
          // host: "igtools-db",
          host: "127.0.0.1",
          port: 5432,
          username: 'postgres',
          // username: 'root',
          // password: "Bqr7kKtN2GbgAajCFfU1J2Jk",
          password: "Po219219",
          database: 'user_management',
          // database: 'igtools',
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.disable,
        ));
  }

  Future<bool> userExists(String email) async {
    final result = await _connection!.execute(
      Sql.named("SELECT * FROM users WHERE email=@email"),
      parameters: {'email': email},
    );
    return result.length == 1; // If one user was found
  }

  Future<bool> updateData(
      {required String query, required Map<String, dynamic> data}) async {
    final result = await _connection!.execute(
      Sql.named(query),
      parameters: data,
    );
    return true;
  }

  Future<int> getUserID(String email) async {
    final result = await _connection!.execute(
      Sql.named("select id,email from users where email like @email;"),
      parameters: {'email': email},
    );
    return int.tryParse(result.first[0].toString()) ??
        0; // If one user was found
  }

  Future<bool> checkLogin(String email, String passwordHash) async {
    final result = await _connection!.execute(
      Sql.named(
          "SELECT * FROM users WHERE email = @email and password = @password"),
      parameters: {'email': email, 'password': passwordHash},
    );
    return result.length == 1; // If one user was found
  }

  Future<void> insertUser(String email, String passwordHash) async {
    await _connection!.execute(
      Sql.named(
          'INSERT INTO users (email, password, has_plan) VALUES (@email, @password, @has_plan)'),
      parameters: {
        'email': email,
        'password': passwordHash,
        'has_plan': false,
      },
    );
  }

  Future<Map> getUserInfo(String id) async {
    final result = await _connection!.execute(
      Sql.named('SELECT * FROM users WHERE id = @id'),
      parameters: {
        'id': id,
      },
    );
    String firstName = result.first.toColumnMap()['firstname'].toString();
    String lastname = result.first.toColumnMap()['lastname'].toString();
    String email = result.first.toColumnMap()['email'].toString();
    String image = result.first.toColumnMap()['image'].toString();
    final has_plan = result.first.toColumnMap()['has_plan'].toString() == '1';
    final userId = result.first.toColumnMap()['id'];
    List accountsList = await getUserAccounts(id);
    Map data = {
      'firstName': firstName,
      'lastname': lastname,
      'email': email,
      'image': image,
      'has_plan': has_plan,
      'userId': userId,
      'accounts': accountsList,
    };
    return data;
  }

  Future<Map> getUserHistory(int id, String accountId) async {
    final result = await _connection!.execute(
      Sql.named(
          'SELECT * FROM user_request_history WHERE userId = @id, account_id = @accountId'),
      parameters: {
        'id': id,
        'accountId': accountId,
      },
    );
    final historyList = result.toList();
    List history = [];
    for (ResultRow each in historyList) {
      Map e = {};
      e['id'] = each.toColumnMap()['id'].toString();
      e['date'] = each.toColumnMap()['request_date'].toString();
      e['type'] = each.toColumnMap()['request_type'].toString();
      e['status'] = each.toColumnMap()['status'].toString();
      history.add(e);
    }
    Map data = {
      'history': history,
    };
    return data;
  }

  Future<void> insertUserAccount(String userId, String string) async {
    await _connection!.execute(
      Sql.named(
          'INSERT INTO user_strings (user_id, string_value) VALUES (@userId, @string)'),
      parameters: {
        'userId': userId,
        'string': string,
      },
    );
  }

  Future<List> getUserAccounts(String id) async {
    final listResult = await _connection!.execute(
      Sql.named('SELECT * FROM user_strings WHERE user_id = @id'),
      parameters: {
        'id': id,
      },
    );
    final accounts = listResult.toList();
    List<String> accountsList = [];
    for (ResultRow each in accounts) {
      String e = each.toColumnMap()['string_value'].toString();
      accountsList.add(e);
    }
    List<Future> requests = [];
    Network network = Network();
    for (var each in accountsList) {
      String token = each.split('#poqi#').first;
      String finalToken = token.split('bearer ').last;
      requests.add(network.getAccountDetail(finalToken));
    }
    List responses = await Future.wait(requests);
    List userAccounts = [];
    for (var each in responses) {
      Map map = jsonDecode(each.toString()) as Map;
      userAccounts.add(map);
    }
    return userAccounts;
  }

  Future<Map> getIGAccountInfo(String id, int index) async {
    final listResult = await _connection!.execute(
      Sql.named('SELECT * FROM user_strings WHERE user_id = @id'),
      parameters: {
        'id': id,
      },
    );
    final accounts = listResult.toList();
    List<String> accountsList = [];
    for (ResultRow each in accounts) {
      String e = each.toColumnMap()['string_value'].toString();
      accountsList.add(e);
    }
    String value = accountsList[index];
    List<String> temp = value.split('#poqi#');
    return {
      'token': temp[0].toString(),
      'id': temp[1].toString(),
    };
  }

  Future<void> close() async {
    await _connection!.close();
  }
}
