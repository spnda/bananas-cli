import 'dart:io';

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
  void run() async {
    var auth = GitHubAuth('ape');
    var token = await auth.readFromFile();
    if (token != null) {
      /// If we already have credentials saved, ask the user if we really want to 
      /// get new credentials.
      final answer = Confirm(
        prompt: 'Are you sure you want to re-authenticate?',
        defaultValue: false,
        waitForNewLine: true,
      ).interact();
      if (!answer) return;
    }

    final location = await auth.authenticate();
    print('!'.yellow() + ' Please open the following URL to authenticate: ' + location);

    token = await auth.waitForAccessToken(location);
    print('✓'.green() + ' Successfully authenticated.'.bold());

    // As the program locks up here, we're going to forcefully exit it.
    exit(0);
  }
}
