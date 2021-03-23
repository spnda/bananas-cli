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
    if (argResults == null) return;
    final arguments = List.from(argResults!.rest);

    if (arguments.isEmpty) {
      /// TODO: Improve error message.
      print('No arguments passed.');
      return;
    }

    /// Get the bananas content-type from the first argument.
    var contentType = BananasContentType.newgrf; // Default content-type.
    try {
      contentType = BananasContentTypeExt.fromString(arguments[0]);
    } on Error {
      contentType = BananasContentType.invalid;
    }

    if (arguments.length == 1 && arguments.isNotEmpty && contentType == BananasContentType.invalid) {
      /// All the commands requiring no content type to function.
      switch(arguments[0]) {
        case 'self':
          await GitHubAuth('ape').init();
          final packages = await BaNaNaS.bananas.getMyPackages();
          _printPackages(packages, 'Showing your ${packages.length} packages.');
          break;
        default:
          print('${arguments[0]} is not a command. See \'bananas help packages\'.');
      }
    } else {
      if (arguments.length == 1) {
        /// If no content-type was passed, we'll just run the list command.
        arguments.add('list');
      }

      /// All the commands requiring a content type to function.
      switch (arguments[1]) {
        case 'list':
          var pageIndex = arguments.length >= 3 ? int.tryParse(arguments[2]) : 0;
          pageIndex ??= 0;
          final packages = await getPackages(contentType: contentType);
          var countToShow = min(20, packages.length);
          final offset = pageIndex * countToShow;
          if (offset + countToShow > packages.length) break;
          _printPackages(packages.sublist(pageIndex == 1 ? 0 : offset, offset + countToShow), 'Showing $countToShow of ${packages.length} ${contentType.getHumanReadable()}s available');
          break;
        case 'info':
          final query = argResults!.arguments.last;
          try {
            final package = await BaNaNaS.bananas.getPackage(contentType, query);
            print(package.asInfoString());
          } on Error catch (e) {
            print(e);
          }
          break;
        default:
          final query = arguments[1];
          /// If the last argument is a 8 digit long hexadecimal integer, we'll
          /// interpret it as a content ID and will search using that instead.
          List<Package> packages;
          if (query.length == 8 && int.tryParse(query, radix: 16) != null) {
            packages = [await BaNaNaS.bananas.getPackage(contentType, query)];
          } else {
            packages = (await getPackages(contentType: contentType)).where((package) {
              return package.name.toLowerCase().contains(query.toLowerCase());
            }).toList();
          }
          if (packages.length == 1) {
            print(packages.first.asInfoString());
          } else {
            _printPackages(packages, 'Found ${packages.length} ${contentType.getHumanReadable()}s matching your search');
          }
          break;
      }
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
