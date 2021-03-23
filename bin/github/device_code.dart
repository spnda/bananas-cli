class GitHubDeviceCode {
  late final String deviceCode;
  late final String userCode;
  late final String verificationUri;
  late final int expiresIn;
  late final int interval;

  GitHubDeviceCode({required this.deviceCode, required this.userCode, required this.verificationUri, required this.expiresIn, required this.interval});

  GitHubDeviceCode.fromJson(Map<String, dynamic> json) {
    deviceCode = json['device_code'];
    userCode = json['user_code'];
    verificationUri = json['verification_uri'];
    expiresIn = json['expires_in'];
    interval = json['interval'];
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['device_code'] = deviceCode;
    data['user_code'] = userCode;
    data['verification_uri'] = verificationUri;
    data['expires_in'] = expiresIn;
    data['interval'] = interval;
    return data;
  }
}
