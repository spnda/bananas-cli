import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:tint/tint.dart';
import 'package:path/path.dart' as path;

import '../bananas/bananas.dart';
import '../bananas/bananas_url.dart';
import '../utilities/home_directory.dart';
import 'token.dart';

class GitHubAuth {
  final Random _random = Random();

  String _getRandomHexString(int length) 
    => List.generate(length, (_) => _random.nextInt(255).toRadixString(16).padLeft(2, '0')).fold<String>('', (prev, element) => prev + element);

  Future<ProcessResult> openUrl(String url) {
    return Process.run(_command, [url], runInShell: true);
  }

  String get _command {
    if (Platform.isWindows) {
      return 'start';
    } else if (Platform.isLinux) {
      return 'xdg-open';
    } else if (Platform.isMacOS) {
      return 'open';
    } else {
      throw UnsupportedError('Operating system not supported by the open_url '
          'package: ${Platform.operatingSystem}');
    }
  }

  final String clientId;

  String _codeVerifier = '';

  final File _file = File(path.join(getApplicationDataDirectory(), 'bananas-cli', 'token'));

  GitHubAuth(this.clientId);

  Future<Token> init() async {
    try {
      final token = await readFromFile();
      if (token == null) {
        throw Exception('No auth token could be read.');
      } else {
        if (!(await validate(token.accessToken))) {
          throw Exception('Invalid auth token.');
        }
        return token;
      }
    } on Exception {
      print('!'.padRight(2).red() + 'Unauthenticated: Please login first.');
      rethrow;
    }
  }

  Future<bool> validate(String token) async {
    final uri = Uri.https(apiBase, 'user');
    final request = await http.get(uri, headers: {
      HttpHeaders.authorizationHeader: 'Bearer $token',
    });
    return request.statusCode == 200;
  }

  Future<Token?> readFromFile() async {
    if (_file.existsSync()) {
      final data = _file.readAsStringSync();
      if (data.isEmpty) return null;
      final token = Token(accessToken: data, tokenType: 'Bearer');
      BaNaNaS.bananas.accessToken = token.accessToken;
      return token;
    } else {
      return null;
    }
  }

  Future<void> writeToFile(Token token) async {
    final dir = Directory(path.dirname(_file.path));
    if (!dir.existsSync()) dir.createSync();
    if (!_file.existsSync()) _file.createSync();
    _file.writeAsStringSync(token.accessToken);
  }

  // The BaNaNaS API handles GH Authentication for us,
  // sadly doesn't use the device flow.
  // So this is going to be the 'shitty' version of authentication
  // for now, until someone fixes that.
  Future<String> authenticate() async {
    _codeVerifier = _getRandomHexString(32);

    final sdsad = sha256.convert(utf8.encode(_codeVerifier)).bytes;
    var code_challenge = base64.encode(sdsad);
    code_challenge = code_challenge.replaceAll('+', '-').replaceAll('/', '_');

    final authUri = Uri.https(apiBase, 'user/authorize', {
      'audience': 'github', 
      'redirect_uri': 'http://localhost:3977/redirect', 
      'response_type': 'code', 
      'client_id': clientId, 
      'code_challenge': code_challenge.replaceFirst('=', '', code_challenge.length - 2), 
      'code_challenge_method': 'S256'
    });
    final req = http.Request('GET', authUri)..followRedirects = false;
    final authResponse = await http.Client().send(req);
    if (authResponse.statusCode != 302) {
      //throw Exception(json.decode(authResponse.body)['message']);
    }

    return authResponse.headers['location'] ?? '';
  }

  Future<Token> waitForAccessToken(String uri) async {
    final server = await HttpServer.bind('localhost', 3977);
    final firstRequest = await server.first;
    final code = firstRequest.requestedUri.queryParameters['code'];

    // Send a basic response to the browser.
    firstRequest.response.writeln('Done.');
    await firstRequest.response.close();

    final accessData = await http.post(Uri.https(apiBase, '/user/token'), body: json.encode({
      'client_id': clientId, 
      'redirect_uri': 'http://localhost:3977/redirect', 
      'code_verifier': _codeVerifier, 
      'code': code, 
      'grant_type': 
      'authorization_code'
    }), headers: {HttpHeaders.contentTypeHeader: 'application/json'});
    if (accessData.statusCode != 200) {
      throw Exception('Couldn\'t get access token.');
    }
    final token = Token.fromJson(json.decode(accessData.body));
    BaNaNaS.bananas.accessToken = token.accessToken;
    await writeToFile(token);
    return token;
  }
}
