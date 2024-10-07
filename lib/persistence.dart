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
    return data;
  }

  Future<Map> getUserHistory(int id, String accountId) async {
    print('id: $id');
    print('accountId: $accountId');
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
    return data;
  }

  Future<void> insertUserAccount(
      String userId, String string, String expireAt) async {
    await _connection!.execute(
      Sql.named(
          'INSERT INTO user_strings (user_id, string_value, expire_at) VALUES (@userId, @string, @expire_at)'),
      parameters: {
        'userId': userId,
        'string': string,
        'expire_at': expireAt,
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

  Future<Map> getUserPlan(String id) async {
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
  }

  Future<Map> getPlanInfo(String id) async {
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
    return data;
  }

  Future<void> addPlan(
      {required String name,
      required String description,
      required String price,
      required String duration}) async {
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
  }

  Future<Map> getPaymentInfo(String orderId) async {
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
    return data;
  }

  Future<void> setUserPlan(
      {required String planId, required String userId}) async {
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
  }

  Future<void> resetPlans() async {
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
  }

  Future<List<Map>> getExpiredTokens() async {
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
    return data;
  }

  Future<void> close() async {
    await _connection!.close();
  }
}
