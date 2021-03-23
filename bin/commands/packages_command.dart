import 'dart:math';

import 'package:args/command_runner.dart';
import 'package:tint/tint.dart';

import '../bananas/bananas.dart';
import '../bananas/content_type.dart';
import '../bananas/package.dart';
import '../github/github_auth.dart';

class PackagesCommand extends Command {
  @override
  String get description => 'Get stats about all packages';

  @override
  String get name => 'packages';

  PackagesCommand() {
    argParser.addCommand('list');
    argParser.addCommand('search');
    argParser.addCommand('info');
    argParser.addCommand('self');
  }

  List<Package>? _cached_packages;

  Future<List<Package>> getPackages({BananasContentType contentType = BananasContentType.newgrf}) async {
    if (_cached_packages == null) {
      return BaNaNaS.bananas.getPackages(contentType: BananasContentType.newgrf);
    } else {
      return _cached_packages!;
    }
  }

  @override
  void run() async {
    if (argResults!.command == null) {
      print(argParser.usage);
      return;
    }
    switch (argResults!.command!.name) {
      case 'list':
        final packages = await getPackages();
        var countToShow = min(20, packages.length);
        _printPackages(packages.sublist(0, countToShow), 'Showing $countToShow of ${packages.length} NewGRFs available');
        break;
      case 'search':
        final query = argResults!.arguments.last;
        final packages = (await getPackages()).where((package) {
          return package.name.toLowerCase().contains(query.toLowerCase());
        }).toList();
        _printPackages(packages, 'Found ${packages.length} NewGRFs matching your search');
        break;
      case 'info':
        final query = argResults!.arguments.last;
        try {
          final package = (await getPackages()).firstWhere((package) {
            return package.uniqueId.contains(query);
          });
          print(package.asInfoString());
        } on Error catch (e) {
          print(e);
          print('Could not find package with id $query.');
        }
        break;
      case 'self':
        await GitHubAuth('ape').init();
        final packages = await BaNaNaS.bananas.getMyPackages();
        _printPackages(packages, 'Showing your ${packages.length} packages.');
        break;
      default:
        throw Error();
    }
  }

  void _printPackages(List<Package> packages, String text) {
    print('\n$text\n');

    var nameColumnSize = 0;
    var descColumnSize = 0;
    var idColumnSize = 0;
    var versionColumnSize = 0;
    for (var package in packages) {
      if (package.name.length > nameColumnSize) nameColumnSize = package.name.length;

      if (package.description != null && package.description!.length > descColumnSize) {
        descColumnSize = package.description!.length;
      }

      if (package.uniqueId.length > idColumnSize) idColumnSize = package.uniqueId.length;

      final latestVersion = package.latestVersion;
      if (latestVersion.length > nameColumnSize) latestVersion.length;
    }

    for (var i = 0; i < packages.length; i++) {
      final buffer = StringBuffer();

      var package = packages[i];
      _print(package.name, nameColumnSize, buffer);

      _print(package.uniqueId, idColumnSize, buffer);

      _print(package.latestVersion.gray(), versionColumnSize, buffer);

      print(buffer.toString());
    }
  }

  void _print(String? str, int size, StringBuffer buffer) {
    if (str == null) return;
    buffer.write(str);
    for (var i = 0; i < (size + 3 - str.length); i++) {
      buffer.write(' ');
    }
  }
}
