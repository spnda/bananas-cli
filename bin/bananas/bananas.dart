import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../github/token.dart';
import 'bananas_url.dart';
import 'license.dart';
import 'new_package_info.dart';
import 'package.dart';

import 'package:http/http.dart' as http;

import '../bananas/content_type.dart';
import 'package_exception.dart';

class BaNaNaS {
  Token accessToken = Token(accessToken: '', tokenType: 'Bearer');

  static BaNaNaS bananas = BaNaNaS();

  BaNaNaS();

  /// Get all packages published by me.
  Future<List<Package>> getMyPackages() async {
    var url = Uri.https(apiBase, '/package/self');
    var contents = (await http.get(url, headers: {
      HttpHeaders.authorizationHeader: accessToken.asHeader(),
    })).body;
    final data = json.decode(contents.toString());
    if (data is Map && data['message'] != null) {
      throw ArgumentError(data['message']);
    }
    final ret = <Package>[];
    for (var element in (data as List)) {
      ret.add(Package.fromJson(element));
    }
    return ret;
  }

  /// Get a list of packages.
  Future<List<Package>> getPackages({BananasContentType contentType = BananasContentType.newgrf, DateTime? since}) async {
    since ??= DateTime.fromMillisecondsSinceEpoch(0);
    // Does .toUtc() so that timezone information is passed to the API, which requires this.
    var url = Uri.https(apiBase, '/package/${contentType.get()}', {'since': since.toUtc().toIso8601String()});
    var contents = (await http.get(url)).body;
    final data = json.decode(contents.toString());
    if (data is Map && data['message'] != null) {
      throw ArgumentError(data['message']);
    }
    final ret = <Package>[];
    for (var element in (data as List)) {
      ret.add(Package.fromJson(element));
    }
    return ret;
  }

  /// Get a package by ID.
  Future<Package> getPackage(BananasContentType contentType, String uuid) async {
    var url = Uri.https(apiBase, '/package/${contentType.get()}/$uuid');
    var response = await http.get(url);
    if (response.statusCode != 200) throw Exception('Could not find package for $uuid');
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['message'] != null) {
      throw ArgumentError(data['message']);
    }
    return Package.fromJson(data);
  }

  /// UPDATE
   
  /// Update the global information of a single package.
  Future<Package> updateGlobalPackageInfo(Package package, {DateTime? dateTime}) async {
    var endpoint = '/package/${package.contentType.get()}/${package.uniqueId}';
    if (dateTime != null) endpoint += '/${dateTime.toUtc().toIso8601String()}';
    var url = Uri.https(apiBase, endpoint);
    print(json.encode(package.toJson()));

    /// Some values are not supposed to be 'updated' by this, therefore
    /// we'll remove them.
    var packageJson = package.toJson();
    packageJson.remove('content-type');
    packageJson.remove('unique-id');
    packageJson.remove('authors');
    packageJson.remove('versions');

    var response = await http.put(url,
      body: json.encode(packageJson),
      headers: {
        HttpHeaders.authorizationHeader: accessToken.asHeader(),
      }
    );
    if (response.statusCode != 204) {
      final responseJson = json.decode(response.body);
      throw Exception('${responseJson['message']}: ${responseJson['errors']}');
    }

    return package; // Just return the same package again.
  }

  /// NEW PACKAGE
   
  /// Start with the creation of a new package or version.
  Future<String> newPackage() async {
    var url = Uri.https(apiBase, '/new-package');
    var response = (await http.post(url, headers: {
      HttpHeaders.authorizationHeader: accessToken.asHeader(),
    }));
    if (response.statusCode != 200) throw Exception(response.body);
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['message'] != null) {
      throw Exception(data['message']);
    }
    return data['upload-token'];
  }

  /// Get information about the new upload.
  Future<NewPackageInfo> getNewPackageInfo(String uploadToken) async {
    var url = Uri.https(apiBase, '/new-package/$uploadToken');
    var contents = (await http.get(url, headers: {
      HttpHeaders.authorizationHeader: accessToken.asHeader(),
    })).body;
    final data = json.decode(contents.toString()) as Map<String, dynamic>;
    if (data['message'] != null) {
      throw Exception(data['message']);
    }
    return NewPackageInfo.fromJson(data);
  }

  /// Update the information of a new upload.
  Future<bool> updatePackageInfo(String uploadToken, NewPackageInfo packageInfo) async {
    var url = Uri.https(apiBase, '/new-package/$uploadToken');
    var response = await http.put(url, headers: {
      HttpHeaders.authorizationHeader: accessToken.asHeader(),
    }, body: json.encode(packageInfo.toJson()));
    if (response.statusCode == 204) return true;
    var jsonResponse = json.decode(response.body);
    if (jsonResponse['message'] != null) {
      throw Exception(jsonResponse['message']);
    }
    return false;
  }

  /// Publish the new upload?
  Future<NewPackageInfo> publishNewPackage(String uploadToken) async {
    var url = Uri.https(apiBase, '/new-package/$uploadToken/publish');
    var response = await http.post(url, headers: {
      HttpHeaders.authorizationHeader: accessToken.asHeader(),
    });
    if (response.statusCode != 201) {
      final responseJson = json.decode(response.body);
      throw PackageException(responseJson['message'], responseJson['errors'].cast<String>());
    }
    return NewPackageInfo.fromJson(json.decode(response.body));
  }

  /// CONFIG

  /// Get all licenses.
  Future<List<License>> getLicenses() async {
    var url = Uri.https(apiBase, '/config/licenses');
    var response = await http.get(url);
    return (json.decode(response.body) as List).map((v) => License.fromJson(v)).toList();
  }
}
