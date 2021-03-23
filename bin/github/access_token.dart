class GitHubAccessToken {
  late final String accessToken;
  late final String tokenType;
  late final String scope;

  GitHubAccessToken({required this.accessToken, required this.tokenType, required this.scope});

  GitHubAccessToken.fromJson(Map<String, dynamic> json) {
    accessToken = json['access_token'];
    tokenType = json['token_type'];
    scope = json['scope'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['access_token'] = accessToken;
    data['token_type'] = tokenType;
    data['scope'] = scope;
    return data;
  }
}
