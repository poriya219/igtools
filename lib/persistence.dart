import 'dart:convert';

import 'package:crypto/crypto.dart';
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

  Future<int?> userExists(String email) async {
    await connect();
    final result = await _connection!.execute(
      Sql.named("SELECT * FROM users WHERE email=@email"),
      parameters: {'email': email},
    );
    await _connection!.close();
    if (result.isNotEmpty) {
      int? id = int.tryParse(result.first.toColumnMap()['id'].toString());
      return id;
    } else {
      return null;
    }
  }

  Future<bool> updateData(
      {required String query, required Map<String, dynamic> data}) async {
    await connect();
    final result = await _connection!.execute(
      Sql.named(query),
      parameters: data,
    );
    await _connection!.close();
    return true;
  }

  Future<int> getUserID(String email) async {
    await connect();
    final result = await _connection!.execute(
      Sql.named("select id,email from users where email like @email;"),
      parameters: {'email': email},
    );
    await _connection!.close();
    return int.tryParse(result.first[0].toString()) ??
        0; // If one user was found
  }

  Future<bool> checkLogin(String email, String passwordHash) async {
    await connect();
    final result = await _connection!.execute(
      Sql.named(
          "SELECT * FROM users WHERE email = @email and password = @password"),
      parameters: {'email': email, 'password': passwordHash},
    );
    await _connection!.close();
    return result.length == 1; // If one user was found
  }

  Future<void> insertUser(String email, String passwordHash) async {
    await connect();
    await _connection!.execute(
      Sql.named(
          'INSERT INTO users (email, password, has_plan) VALUES (@email, @password, @has_plan)'),
      parameters: {
        'email': email,
        'password': passwordHash,
        'has_plan': false,
      },
    );
    await _connection!.close();
  }

  Future<Map> getUserInfo(String id) async {
    await connect();
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
    String expireAt = result.first.toColumnMap()['expire_at'].toString();
    bool has_plan =
        bool.tryParse(result.first.toColumnMap()['has_plan'].toString()) ??
            false;
    final userId = result.first.toColumnMap()['id'];

    List accountsList = await getUserAccounts(id);
    Map data = {
      'firstName': firstName,
      'lastname': lastname,
      'email': email,
      'image': image,
      'has_plan': has_plan,
      'expire_at': expireAt,
      'userId': userId,
      'accounts': accountsList,
    };
    await _connection!.close();
    return data;
  }

  Future<Map> getUserHistory(int id, int index) async {
    await connect();
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
    String accountId = accountsList[index].split('#poqi#').last;
    final result = await _connection!.execute(
      Sql.named(
          'SELECT * FROM user_request_history WHERE user_id = @user_id and account_id = @accountId'),
      parameters: {
        'user_id': id,
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
    print('history: $data');
    await _connection!.close();
    return data;
  }

  Future<void> insertUserAccount(
      String userId, String string, String expireAt) async {
    await connect();
    await _connection!.execute(
      Sql.named(
          'INSERT INTO user_strings (user_id, string_value, expire_at) VALUES (@userId, @string, @expire_at)'),
      parameters: {
        'userId': userId,
        'string': string,
        'expire_at': expireAt,
      },
    );
    await _connection!.close();
  }

  Future<List> getUserAccounts(String id) async {
    await connect();
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
    await _connection!.close();
    return userAccounts;
  }

  Future<Map> getIGAccountInfo(String id, int index) async {
    await connect();
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
    await _connection!.close();
    return {
      'token': temp[0].toString(),
      'id': temp[1].toString(),
    };
  }

  Future<Map> getUserPlan(String id) async {
    await connect();
    final result = await _connection!.execute(
      Sql.named('SELECT * FROM users WHERE id = @id'),
      parameters: {
        'id': id,
      },
    );
    bool hasPlan =
        bool.tryParse(result.first.toColumnMap()['has_plan'].toString()) ??
            false;
    String expireAt = result.first.toColumnMap()['expire_at'].toString();
    await _connection!.close();
    return {
      'has_plan': hasPlan,
      'expire_at': expireAt,
    };
  }

  Future<void> addPayment(
      {required String user_id,
      required String amount,
      required String orderId,
      String? planId,
      required String trackId}) async {
    await connect();
    await _connection!.execute(
      Sql.named(
          'INSERT INTO user_purchase_history (user_id, purchase_date, amount, track_Id, status, order_Id, plan_id) VALUES (@user_id, @purchase_date, @amount, @trackId, @status, @orderId, @plan_id)'),
      parameters: {
        'user_id': user_id,
        'purchase_date': DateTime.now().toString(),
        'amount': int.tryParse(amount) ?? 0,
        'trackId': trackId,
        'orderId': orderId,
        'status': 'pending',
        'plan_id': planId,
      },
    );
    await _connection!.close();
  }

  Future<Map> getPlanInfo(String id) async {
    await connect();
    final result = await _connection!.execute(
      Sql.named('SELECT * FROM plans WHERE id = @id'),
      parameters: {
        'id': id,
      },
    );
    String name = result.first.toColumnMap()['name'].toString();
    String description = result.first.toColumnMap()['description'].toString();
    String duration = result.first.toColumnMap()['duration'].toString();
    String price = result.first.toColumnMap()['price'].toString();
    Map data = {
      'name': name,
      'description': description,
      'duration': int.tryParse(duration) ?? 0,
      'price': price,
    };
    await _connection!.close();
    return data;
  }

  Future<void> addPlan(
      {required String name,
      required String description,
      required String price,
      required String duration}) async {
    await connect();
    await _connection!.execute(
      Sql.named(
          'INSERT INTO plans (name, description, price, duration) VALUES (@name, @description, @price, @duration)'),
      parameters: {
        'name': name,
        'description': description,
        'price': price,
        'duration': int.tryParse(duration) ?? 0,
      },
    );
    await _connection!.close();
  }

  Future<Map> getPaymentInfo(String orderId) async {
    await connect();
    final result = await _connection!.execute(
      Sql.named(
          'SELECT * FROM user_purchase_history WHERE order_id = @order_id'),
      parameters: {
        'order_id': orderId,
      },
    );
    String user_id = result.first.toColumnMap()['user_id'].toString();
    String purchase_date =
        result.first.toColumnMap()['purchase_date'].toString();
    String amount = result.first.toColumnMap()['amount'].toString();
    String description = result.first.toColumnMap()['description'].toString();
    String track_id = result.first.toColumnMap()['track_id'].toString();
    String status = result.first.toColumnMap()['status'].toString();
    String order_id = result.first.toColumnMap()['order_id'].toString();
    String id = result.first.toColumnMap()['id'].toString();
    String plan_id = result.first.toColumnMap()['plan_id'].toString();
    Map data = {
      'user_id': user_id,
      'purchase_date': purchase_date,
      'amount': amount,
      'description': description,
      'track_id': track_id,
      'status': status,
      'order_id': order_id,
      'id': id,
      'plan_id': plan_id,
    };
    await _connection!.close();
    return data;
  }

  Future<void> setUserPlan(
      {required String planId, required String userId}) async {
    await connect();
    final result = await _connection!.execute(
      Sql.named('SELECT * FROM plans WHERE id = @id'),
      parameters: {
        'id': planId,
      },
    );
    String duration = result.first.toColumnMap()['duration'].toString();
    DateTime expire =
        DateTime.now().add(Duration(days: int.tryParse(duration) ?? 0));
    String expireAt = '${expire.year}-${expire.month}-${expire.day}';
    String query =
        'UPDATE users SET has_plan = @has_plan, expire_at = @expire_at WHERE id = @id';
    await updateData(query: query, data: {
      'has_plan': true,
      'expire_at': expireAt,
      'id': userId,
    });
    await _connection!.close();
  }

  Future<void> resetPlans() async {
    await connect();
    DateTime now = DateTime.now();
    DateTime expire = now.subtract(const Duration(days: 1));
    String expireAt = '${expire.year}-${expire.month}-${expire.day}';
    await _connection!.execute(
      Sql.named(
          'UPDATE users SET has_plan = @has_plan, expire_at = @expire_at WHERE expire_at = @expireAt'),
      parameters: {
        'has_plan': false,
        'expire_at': null,
        'expireAt': expireAt,
      },
    );
    await _connection!.close();
  }

  Future<List<Map>> getExpiredTokens() async {
    await connect();
    DateTime now = DateTime.now();
    DateTime expire = now.add(const Duration(days: 2));
    String expireAt = '${expire.year}-${expire.month}-${expire.day}';
    final result = await _connection!.execute(
      Sql.named('SELECT * FROM user_strings WHERE expire_at = @expireAt'),
      parameters: {
        'expireAt': expireAt,
      },
    );
    List<Map> data = [];
    for (ResultRow each in result.toList()) {
      String id = each.toColumnMap()['id'].toString();
      String string = each.toColumnMap()['string_value'].toString();
      data.add({
        'id': id,
        'string': string,
      });
    }
    await _connection!.close();
    return data;
  }

  Future<void> savePasswordResetToken(int userId, String token) async {
    await connect();
    final expiration =
        DateTime.now().add(Duration(hours: 1)); // Token valid for 1 hour
    await _connection!.execute(
      Sql.named(
          'INSERT INTO password_reset_tokens (user_id, token, expires_at) VALUES (@id, @token, @expires)'),
      parameters: {
        'id': userId,
        'token': token,
        'expires': expiration.toIso8601String(),
      },
    );
    await _connection!.close();
  }

  Future<Map?> findResetToken(String token) async {
    await connect();
    final result = await _connection!.execute(
      Sql.named('SELECT * FROM password_reset_tokens WHERE token = @token'),
      parameters: {'token': token},
    );

    if (result.isNotEmpty) {
      String expiresAt = result.first.toColumnMap()['expires_at'].toString();
      int userId = int.parse(result.first.toColumnMap()['user_id'].toString());
      await _connection!.close();
      return {
        'expires_at': expiresAt,
        'user_id': userId,
      };
    }

    await _connection!.close();
    return null;
  }

  Future<void> updateUserPassword(int userId, String password) async {
    final bytes = utf8.encode(password); // convert to utf8
    final digest = sha256.convert(bytes);
    final hashedPassword = digest.toString(); // store the hash
    await connect();
    final result = await _connection!.execute(
      Sql.named('UPDATE users SET password = @password WHERE id = @id'),
      parameters: {
        'password': hashedPassword,
        'id': userId,
      },
    );
    await _connection!.close();
  }

  Future<void> invalidateResetToken(String token) async {
    await connect();
    final result = await _connection!.execute(
      Sql.named('DELETE FROM password_reset_tokens WHERE token = @token'),
      parameters: {
        'token': token,
      },
    );
    await _connection!.close();
  }

  Future<void> close() async {
    await _connection!.close();
  }
}
