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
    final token = await auth.readFromFile();
    if (token != null) {
      final valid = await auth.validate(token);
      if (valid) {
        /// The saved credentials are valid, ask the user if we really want to 
        /// get new credentials.
        final answer = Confirm(
          prompt: 'Are you sure you want to re-authenticate?',
          defaultValue: false,
          waitForNewLine: true,
        ).interact();
        if (!answer) return;
      } else {
        print('!'.padRight(2).yellow() + 'The saved credentials are not valid.');
      }
    }

    final location = await auth.authenticate();
    print('!'.padRight(2).yellow() + 'Please open the following URL to authenticate: ' + location);

    await auth.waitForAccessToken(location);
    print('✔'.padRight(2).green() + 'Successfully authenticated.'.bold());

    // As the program locks up here, we're going to forcefully exit it.
    exit(0);
  }
}
