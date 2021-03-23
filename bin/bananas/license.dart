class License {
  late final String name;
  late final bool deprecated;

  License.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    deprecated = json['deprecated'];
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'deprecated': deprecated};
  }
}
