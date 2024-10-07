import 'package:dart_frog/dart_frog.dart';

import '../main.dart';

Future<Response> onRequest(RequestContext context) async {
  // List<int> ids = [1, 2];
  // List<String> newTokens = [
  //   'new token from instagram 1',
  //   'new token from instagram 2'
  // ];
  // List<String> expireDates = ['2024-10-6', '2024-10-7'];
  // final query = """
  //   UPDATE user_strings
  //   SET string_value = sub.new_token, expire_at = sub.expire
  //   FROM (
  //     SELECT  unnest(ARRAY[${ids.map((id) => id.toString()).join(',')}])::INTEGER AS id,
  //      unnest(ARRAY[${newTokens.map((token) => "'$token'").join(',')}])::TEXT AS new_token,
  //      unnest(ARRAY[${expireDates.map((token) => "'$token'").join(',')}])::TEXT AS expire
  //   ) AS sub
  //   WHERE user_strings.id = sub.id;
  // """;
  // await mysqlClient.updateData(query: query, data: {});
  return Response.json(
    statusCode: 200,
  );
}
