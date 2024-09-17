class IGRequest {
  final String token;
  final String url;
  final String time;
  final String userID;

  IGRequest(
      {required this.token,
      required this.url,
      required this.time,
      required this.userID});
}
