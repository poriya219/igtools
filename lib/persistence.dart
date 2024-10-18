import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:igtools/network.dart';
import 'package:postgres/postgres.dart';

class FrogMysqlClient {
  factory FrogMysqlClient() {
    return _inst;
  }
  FrogMysqlClient._internal() {
    connect();
  }
  static final FrogMysqlClient _inst = FrogMysqlClient._internal();

  final bool isDevMode = false;

  Connection? _connection;

  /// initialises a connection to database
  Future<void> connect() async {
    _connection = await Connection.open(
        isDevMode
            ? Endpoint(
                host: "127.0.0.1",
                port: 5432,
                username: 'postgres',
                password: "Po219219",
                database: 'user_management',
              )
            : Endpoint(
                host: "igtools-db",
                port: 5432,
                username: 'root',
                password: "Bqr7kKtN2GbgAajCFfU1J2Jk",
                database: 'igtools',
              ),
        settings: ConnectionSettings(
          sslMode: SslMode.disable,
        ));
  }

  Future<int?> userExists(String email) async {
    final result = await _connection!.execute(
      Sql.named("SELECT * FROM users WHERE email=@email"),
      parameters: {'email': email},
    );
    if (result.isNotEmpty) {
      int? id = int.tryParse(result.first.toColumnMap()['id'].toString());
      return id;
    } else {
      return null;
    }
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
    int? planId =
        int.tryParse(result.first.toColumnMap()['plan_id'].toString());
    int maxAccount =
        int.tryParse(result.first.toColumnMap()['max_account'].toString()) ?? 0;
    int uploadLimit =
        int.tryParse(result.first.toColumnMap()['upload_limit'].toString()) ??
            0;
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
      'plan_id': planId,
      'max_account': maxAccount,
      'upload_limit': uploadLimit.toDouble(),
    };
    return data;
  }

  Future<List> getPaymentPlans() async {
    final result = await _connection!.execute(
      Sql.named('SELECT * FROM plans'),
    );
    List data = [];
    for (ResultRow each in result) {
      int id = int.parse(each.toColumnMap()['id'].toString());
      int duration = int.parse(each.toColumnMap()['duration'].toString());
      String name = each.toColumnMap()['name'].toString();
      String description = each.toColumnMap()['description'].toString();
      String price = each.toColumnMap()['price'].toString();
      int maxAccount =
          int.tryParse(each.toColumnMap()['max_account'].toString()) ?? 0;
      int uploadLimit =
          int.tryParse(each.toColumnMap()['upload_limit'].toString()) ?? 0;
      data.add({
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'duration': duration,
        'upload_limit': uploadLimit.toDouble(),
        'max_account': maxAccount,
      });
    }
    return data;
  }

  Future<Map> getUserHistory(int id, int index) async {
    final listResult = await _connection!.execute(
      Sql.named('SELECT * FROM user_accounts WHERE user_id = @id'),
      parameters: {
        'id': id,
      },
    );
    final accounts = listResult.toList();
    List<String> accountsList = [];
    for (ResultRow each in accounts) {
      String e = each.toColumnMap()['ig_id'].toString();
      accountsList.add(e);
    }
    final result = await _connection!.execute(
      Sql.named(
          'SELECT * FROM user_request_history WHERE user_id = @user_id and ig_id = @ig_id'),
      parameters: {
        'user_id': id,
        'ig_id': accountsList[index].toString(),
      },
    );
    final historyList = result.toList();
    List history = [];
    for (ResultRow each in historyList) {
      Map e = {};
      e['id'] = int.parse(each.toColumnMap()['id'].toString());
      e['user_id'] = int.parse(each.toColumnMap()['user_id'].toString());
      e['request_date'] = each.toColumnMap()['request_date'].toString();
      e['scheduled_time'] = each.toColumnMap()['scheduled_time'].toString();
      e['ig_id'] = int.parse(each.toColumnMap()['ig_id'].toString());
      e['token'] = each.toColumnMap()['token'].toString();
      e['ig_token'] = each.toColumnMap()['ig_token'].toString();
      e['urls'] = each.toColumnMap()['urls'];
      e['caption'] = each.toColumnMap()['caption'].toString();
      e['type'] = each.toColumnMap()['type'].toString();
      e['status'] = each.toColumnMap()['status'].toString();
      history.insert(0, e);
    }
    Map data = {
      'history': history,
    };
    return data;
  }

  Future<void> addUserRequest({
    required int userId,
    required String scheduledTime,
    required int igId,
    required String token,
    required String igToken,
    required final urls,
    required String caption,
    required String type,
    required String status,
  }) async {
    final result = await _connection!.execute(
      Sql.named(
          'INSERT INTO user_request_history (user_id, request_date, scheduled_time, ig_id, token, ig_token, urls, caption, type, status) VALUES (@user_id, NOW(), @scheduled_time, @ig_id, @token, @ig_token, @urls, @caption, @type, @status)'),
      parameters: {
        'user_id': userId,
        'scheduled_time': scheduledTime,
        'ig_id': igId,
        'token': token,
        'ig_token': igToken,
        'urls': urls,
        'caption': caption,
        'type': type,
        'status': status,
      },
    );
  }

  Future<List<ResultRow>> getRequests() async {
    final result = await _connection!.execute(
      Sql.named(
          "SELECT * FROM user_request_history WHERE date_trunc('minute', scheduled_time) = date_trunc('minute', NOW())"),
    );
    print('requests list: ${result.toList()}');
    return result.toList();
  }

  Future<void> insertUserAccount(String userId, String token, String igId,
      String expireAt, String pai) async {
    await _connection!.execute(
      Sql.named(
          'INSERT INTO user_accounts (user_id, token, ig_id, expire_at, pai) VALUES (@userId, @token, @ig_id, @expire_at, @pai)'),
      parameters: {
        'userId': userId,
        'token': token,
        'ig_id': igId,
        'expire_at': expireAt,
        'pai': pai
      },
    );
  }

  Future<void> insertUserAccountWebhooks(
    String userId,
    String pai,
  ) async {
    await _connection!.execute(
      Sql.named(
          'INSERT INTO user_webhooks (user_id, pai, c, cfc, dfc) VALUES (@userId, @pai, @c, @cfc, @dfc)'),
      parameters: {
        'userId': userId,
        'pai': pai,
        'c': false,
        'cfc': false,
        'dfc': false,
      },
    );
  }

  Future<List> getUserAccounts(String id) async {
    final listResult = await _connection!.execute(
      Sql.named('SELECT * FROM user_accounts WHERE user_id = @id'),
      parameters: {
        'id': id,
      },
    );
    final accounts = listResult.toList();
    List<String> accountsList = [];
    for (ResultRow each in accounts) {
      String e = each.toColumnMap()['token'].toString();
      accountsList.add(e);
    }
    List<Future> requests = [];
    Network network = Network();
    for (var each in accountsList) {
      String finalToken = each.split('bearer ').last;
      requests.add(network.getAccountDetail(finalToken));
    }
    List responses = await Future.wait(requests);
    List userAccounts = [];
    for (var each in responses) {
      Map map = jsonDecode(each.toString()) as Map;
      String pai = map['user_id'].toString();
      Map<String, dynamic> webhooksStatus = await getWebhooksStatus(pai);
      map.addAll(webhooksStatus);
      userAccounts.add(map);
    }
    return userAccounts;
  }

  Future<Map> getIGAccountInfo(String id, int index) async {
    final listResult = await _connection!.execute(
      Sql.named('SELECT * FROM user_accounts WHERE user_id = @id'),
      parameters: {
        'id': id,
      },
    );
    final accounts = listResult.toList();
    List<Map<String, String>> accountsList = [];
    for (ResultRow each in accounts) {
      String id = each.toColumnMap()['ig_id'].toString();
      String token = each.toColumnMap()['token'].toString();
      accountsList.add({
        'ig_id': id,
        'token': token,
      });
    }
    Map<String, String> value = accountsList[index];
    return {
      'token': value['token'].toString(),
      'id': value['ig_id'].toString(),
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
    int? planId =
        int.tryParse(result.first.toColumnMap()['plan_id'].toString());
    int maxAccount =
        int.tryParse(result.first.toColumnMap()['max_account'].toString()) ?? 0;
    int uploadLimit =
        int.tryParse(result.first.toColumnMap()['upload_limit'].toString()) ??
            0;
    return {
      'has_plan': hasPlan,
      'expire_at': expireAt,
      'plan_id': planId,
      'max_account': maxAccount,
      'upload_limit': uploadLimit,
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
    int maxAccount =
        int.tryParse(result.first.toColumnMap()['max_account'].toString()) ?? 0;
    int uploadLimit =
        int.tryParse(result.first.toColumnMap()['upload_limit'].toString()) ??
            0;
    Map data = {
      'name': name,
      'description': description,
      'duration': int.tryParse(duration) ?? 0,
      'price': price,
      'max_account': maxAccount,
      'upload_limit': uploadLimit,
    };
    return data;
  }

  Future<void> addPlan(
      {required String name,
      required String description,
      required String price,
      required int maxAccount,
      required int uploadLimit,
      required String duration}) async {
    await _connection!.execute(
      Sql.named(
          'INSERT INTO plans (name, description, price, duration,max_account,upload_limit) VALUES (@name, @description, @price, @duration, @max_account,@upload_limit)'),
      parameters: {
        'name': name,
        'description': description,
        'price': price,
        'max_account': maxAccount,
        'upload_limit': uploadLimit,
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
    int maxAccount =
        int.tryParse(result.first.toColumnMap()['max_account'].toString()) ?? 0;
    int uploadLimit =
        int.tryParse(result.first.toColumnMap()['upload_limit'].toString()) ??
            0;
    DateTime expire =
        DateTime.now().add(Duration(days: int.tryParse(duration) ?? 0));
    String expireAt = '${expire.year}-${expire.month}-${expire.day}';
    String query =
        'UPDATE users SET has_plan = @has_plan, expire_at = @expire_at, plan_id = @plan_id, max_account = @max_account, upload_limit = @upload_limit WHERE id = @id';
    await updateData(query: query, data: {
      'has_plan': true,
      'expire_at': expireAt,
      'id': userId,
      'max_account': maxAccount,
      'plan_id': int.tryParse(planId),
      'upload_limit': uploadLimit,
    });
  }

  Future<void> resetPlans() async {
    DateTime now = DateTime.now();
    DateTime expire = now.subtract(const Duration(days: 1));
    String expireAt = '${expire.year}-${expire.month}-${expire.day}';
    await _connection!.execute(
      Sql.named(
          'UPDATE users SET has_plan = @has_plan, expire_at = @expire_at, plan_id = @plan_id, max_account = @max_account, upload_limit = @upload_limit WHERE expire_at = @expireAt'),
      parameters: {
        'has_plan': false,
        'expire_at': null,
        'expireAt': expireAt,
        'plan_id': null,
        'max_account': 0,
        'upload_limit': 0,
      },
    );
  }

  Future<List<Map>> getExpiredTokens() async {
    DateTime now = DateTime.now();
    DateTime expire = now.add(const Duration(days: 2));
    String expireAt = '${expire.year}-${expire.month}-${expire.day}';
    final result = await _connection!.execute(
      Sql.named('SELECT * FROM user_accounts WHERE expire_at = @expireAt'),
      parameters: {
        'expireAt': expireAt,
      },
    );
    List<Map> data = [];
    for (ResultRow each in result.toList()) {
      String id = each.toColumnMap()['id'].toString();
      String igId = each.toColumnMap()['ig_id'].toString();
      String token = each.toColumnMap()['token'].toString();
      data.add({
        'id': id,
        'token': token,
        'ig_id': igId,
      });
    }
    return data;
  }

  Future<void> savePasswordResetToken(int userId, String token) async {
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
  }

  Future<Map?> findResetToken(String token) async {
    final result = await _connection!.execute(
      Sql.named('SELECT * FROM password_reset_tokens WHERE token = @token'),
      parameters: {'token': token},
    );

    if (result.isNotEmpty) {
      String expiresAt = result.first.toColumnMap()['expires_at'].toString();
      int userId = int.parse(result.first.toColumnMap()['user_id'].toString());
      return {
        'expires_at': expiresAt,
        'user_id': userId,
      };
    }

    return null;
  }

  Future<void> updateUserPassword(int userId, String password) async {
    final bytes = utf8.encode(password); // convert to utf8
    final digest = sha256.convert(bytes);
    final hashedPassword = digest.toString(); // store the hash
    final result = await _connection!.execute(
      Sql.named('UPDATE users SET password = @password WHERE id = @id'),
      parameters: {
        'password': hashedPassword,
        'id': userId,
      },
    );
  }

  Future<void> invalidateResetToken(String token) async {
    final result = await _connection!.execute(
      Sql.named('DELETE FROM password_reset_tokens WHERE token = @token'),
      parameters: {
        'token': token,
      },
    );
  }

  Future<List> getUserPayments(String userId) async {
    final result = await _connection!.execute(
      Sql.named('SELECT * FROM user_purchase_history WHERE user_id = @user_id'),
      parameters: {
        'user_id': userId,
      },
    );
    List data = [];
    for (ResultRow each in result) {
      String user_id = each.toColumnMap()['user_id'].toString();
      String purchase_date = each.toColumnMap()['purchase_date'].toString();
      String amount = each.toColumnMap()['amount'].toString();
      String description = each.toColumnMap()['description'].toString();
      String track_id = each.toColumnMap()['track_id'].toString();
      String status = each.toColumnMap()['status'].toString();
      String order_id = each.toColumnMap()['order_id'].toString();
      String id = each.toColumnMap()['id'].toString();
      String plan_id = each.toColumnMap()['plan_id'].toString();
      Map record = {
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
      data.insert(0, record);
    }
    return data;
  }

  Future<String> getIgToken(String igId) async {
    final result = await _connection!.execute(
      Sql.named('SELECT * FROM user_accounts WHERE pai = @pai'),
      parameters: {
        'pai': igId,
      },
    );
    if (result.isNotEmpty) {
      String token = result.first.toColumnMap()['token'].toString();
      return token;
    } else {
      return '';
    }
  }

  Future<Map<String, dynamic>> getWebhooksStatus(String pai) async {
    final result = await _connection!.execute(
      Sql.named('SELECT * FROM user_webhooks WHERE pai = @pai'),
      parameters: {
        'pai': pai,
      },
    );
    if (result.isNotEmpty) {
      bool c =
          bool.tryParse(result.first.toColumnMap()['c'].toString()) ?? false;
      bool cfc =
          bool.tryParse(result.first.toColumnMap()['cfc'].toString()) ?? false;
      bool dfc =
          bool.tryParse(result.first.toColumnMap()['dfc'].toString()) ?? false;
      return {
        'c': c,
        'cfc': cfc,
        'dfc': dfc,
      };
    } else {
      return {
        'c': false,
        'cfc': false,
        'dfc': false,
      };
    }
  }

  Future<void> close() async {
    await _connection!.close();
  }
}
