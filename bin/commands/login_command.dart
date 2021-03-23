import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:interact/interact.dart';
import 'package:tint/tint.dart';

import '../github/github_auth.dart';

class LoginCommand extends Command {
  @override
  String get description => 'Prompts the user to login using GitHub to gain access to the BaNaNaS API.';

  @override
  String get name => 'login';

  @override
  FutureOr<bool>? run() async {
    var auth = ShittyGitHubAuth('ape');
    var token = await auth.readFromFile();
    if (token != null) {
      final answer = Confirm(
        prompt: 'Are you sure you want to re-authenticate?',
        defaultValue: false,
        waitForNewLine: true,
      ).interact();
      if (!answer) return Future.value(true);
    }

    final location = await auth.authenticate();
    print('!'.yellow() + ' Please open the following URL to authenticate: ' + location);

    token = await auth.waitForAccessToken(location);
    print('✓'.green() + ' Successfully authenticated.');

    return Future.value(true);
  }
}
