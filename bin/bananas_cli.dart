import 'dart:io';

import 'package:args/command_runner.dart';

import 'commands/manage_command.dart';
import 'commands/packages_command.dart';
import 'commands/login_command.dart';

void main(List<String> args) async {
  var runner = CommandRunner('bananas_cli', 'A CLI for uploading and managing BaNaNaS packages.')
    ..addCommand(ManageCommand())
    ..addCommand(LoginCommand())
    ..addCommand(PackagesCommand());
  await runner.run(args).catchError((error) {
    print(error);
    exit(64);
  });
}
