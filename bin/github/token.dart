class Token {
  late final String accessToken;
  late final String tokenType;

  Token({required this.accessToken, required this.tokenType});

  Token.fromJson(Map<String, dynamic> json) {
    accessToken = json['access_token'];
    tokenType = json['token_type'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['access_token'] = accessToken;
    data['token_type'] = tokenType;
    return data;
  }
}
