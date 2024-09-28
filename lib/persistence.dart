// ignore_for_file: prefer_single_quotes

// import 'package:mysql_client/mysql_client.dart';

// class FrogMysqlClient {
//   factory FrogMysqlClient() {
//     return _inst;
//   }
//   FrogMysqlClient._internal() {
//     print('internal');
//     connect();
//   }
//   static final FrogMysqlClient _inst = FrogMysqlClient._internal();

//   MySQLConnection? _connection;

//   /// initialises a connection to database
//   Future<void> connect() async {
//     print('connect database');
//     _connection = await MySQLConnection.createConnection(
//       host: "127.0.0.1",
//       port: 3306,
//       userName: "root",
//       password: "Po219219@",
//       databaseName: "user_management",
//     );
//     await _connection?.connect();
//   }

//   Future<bool> userExists(String email) async {
//     final result = await _connection!.execute(
//       "SELECT * FROM users WHERE email = :email",
//       {'email': email},
//     );
//     return result.numOfRows == 1; // If one user was found
//   }

//   Future<bool> updateData(
//       {required String query, required Map<String, dynamic> data}) async {
//     final result = await _connection!.execute(
//       query,
//       data,
//     );
//     return true;
//   }

//   Future<int> getUserID(String email) async {
//     final result = await _connection!.execute(
//       "select id,email from users where email like :email;",
//       {'email': email},
//     );
//     return int.tryParse(result.rows.first.colByName('id').toString()) ??
//         0; // If one user was found
//   }

//   Future<bool> checkLogin(String email, String passwordHash) async {
//     final result = await _connection!.execute(
//       "SELECT * FROM users WHERE email = :email and password = :password",
//       {'email': email, 'password': passwordHash},
//     );
//     return result.numOfRows == 1; // If one user was found
//   }

//   Future<void> insertUser(String email, String passwordHash) async {
//     await _connection!.execute(
//       'INSERT INTO users (email, password, has_plan) VALUES (:email, :password, :has_plan)',
//       {
//         'email': email,
//         'password': passwordHash,
//         'has_plan': false,
//       },
//     );
//   }

//   Future<Map> getUserInfo(String id) async {
//     final result = await _connection!.execute(
//       'SELECT * FROM users WHERE id = :id',
//       {
//         'id': id,
//       },
//     );
//     final listResult = await _connection!.execute(
//       'SELECT * FROM accounts WHERE user_id = :id',
//       {
//         'id': id,
//       },
//     );
//     String firstName = result.rows.first.colByName('firstname').toString();
//     String lastname = result.rows.first.colByName('lastname').toString();
//     String email = result.rows.first.colByName('email').toString();
//     String image = result.rows.first.colByName('image').toString();
//     final has_plan =
//         result.rows.first.typedColByName('has_plan').toString() == '1';
//     final userId = result.rows.first.typedColByName('id');
//     final accounts = listResult.rows.toList();
//     List accountsList = [];
//     for (ResultSetRow each in accounts) {
//       String e = each.typedColByName('string_value').toString();

//       accountsList.add(e);
//     }
//     Map data = {
//       'firstName': firstName,
//       'lastname': lastname,
//       'email': email,
//       'image': image,
//       'has_plan': has_plan,
//       'userId': userId,
//       'accounts': accountsList,
//     };
//     return data;
//   }

//   Future<void> close() async {
//     await _connection!.close();
//   }
// }

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
          host: "igtools-db",
          // host: "127.0.0.1",
          port: 5432,
          // username: 'postgres',
          username: 'root',
          password: "Bqr7kKtN2GbgAajCFfU1J2Jk",
          // password: "Po219219",
          // database: 'user_management',
          database: 'igtools',
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
      query,
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
    final listResult = await _connection!.execute(
      Sql.named('SELECT * FROM accounts WHERE user_id = @id'),
      parameters: {
        'id': id,
      },
    );
    // String firstName = result.rows.first.colByName('firstname').toString();
    // String lastname = result.rows.first.colByName('lastname').toString();
    // String email = result.rows.first.colByName('email').toString();
    // String image = result.rows.first.colByName('image').toString();
    // final has_plan =
    //     result.rows.first.typedColByName('has_plan').toString() == '1';
    // final userId = result.rows.first.typedColByName('id');
    // final accounts = listResult.rows.toList();
    // List accountsList = [];
    // for (ResultSetRow each in accounts) {
    //   String e = each.typedColByName('string_value').toString();

    //   accountsList.add(e);
    // }
    // Map data = {
    //   'firstName': firstName,
    //   'lastname': lastname,
    //   'email': email,
    //   'image': image,
    //   'has_plan': has_plan,
    //   'userId': userId,
    //   'accounts': accountsList,
    // };
    return {};
  }

  Future<void> close() async {
    await _connection!.close();
  }
}
