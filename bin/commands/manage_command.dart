import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:interact/interact.dart';
import 'package:tint/tint.dart';
import 'package:path/path.dart';

import '../bananas/bananas.dart';
import '../bananas/bananas_url.dart';
import '../bananas/content_type.dart';
import '../bananas/package.dart';
import '../bananas/package_exception.dart';
import '../bananas/tusd/tusd_client.dart';
import '../github/github_auth.dart';
import '../utilities/md5sum.dart';

class ManageCommand extends Command {
  @override
  String get description => throw UnimplementedError();

  @override
  String get name => 'manage';

  List<Package> myPackages = [];

  @override
  void run() async {
    // Ensure the user is authenticated.
    try {
      await GitHubAuth('ape').init();
    } on Exception {
      return;
    }

    myPackages.addAll(await BaNaNaS.bananas.getMyPackages());

    final optionText = ['Update package', 'Upload new package', 'Delete package'];
    final options = ['update', 'new', 'delete'];
    final chosenOption = Select(
      prompt: 'What do you want to do?', 
      options: optionText
    ).interact();

    switch (options[chosenOption]) {
      case 'update':
      case 'new':
        await uploadNew();
        break;
      case 'delete':
      default:
        throw Exception('Unknown option.');
    }
  }

  /// Method to upload a new package, and a new package only.
  Future<void> uploadNew() async {
    /// Give the user a list of all files in the current directory to choose from.
    /// This might be subject to change, so that we have a more dynamic system.
    final filesInDirectory = Directory.current.listSync();
    final chosenFile = Select(
      prompt: 'Which file do you want to upload?',
      options: filesInDirectory.map((f) => basename(f.path)).toList(),
    ).interact();
    final file = File(filesInDirectory[chosenFile].path);

    final md5sum = await getMd5sumOfFile(file);
    for (final package in myPackages) {
      /// This might not work, as for example with NewGRFs, the md5sum on the server
      /// ignores the sprites. Therefore, md5sums might vary but we'll still check for 
      /// them anyway *just in case*.
      if (package.versions?.first.md5sumPartial == md5sum.substring(md5sum.length - 9)) {
        final resume = Confirm(
          prompt: 'You have already uploaded this file before. Are you sure you want to continue?',
          defaultValue: false,
          waitForNewLine: true,
        ).interact();
        if (!resume) return;
      }
    }

    final uploadToken = await BaNaNaS.bananas.newPackage();
    var newPackageInfo = await BaNaNaS.bananas.getNewPackageInfo(uploadToken);

    bool emptyStringValidator(String value) {
      if (value.isEmpty) {
        throw ValidationError('This field cannot be empty.');
      } else {
        return true;
      }
    }

    /// Get the content type.
    if (newPackageInfo.contentType == null) {
      final contentTypeIndex = Select(
        prompt: 'What content type is this package?',
        options: BananasContentType.values.map((t) => t.getHumanReadable()).toList(),
        initialIndex: 0,
      ).interact();
      final contentType = BananasContentType.values[contentTypeIndex];
      newPackageInfo.contentType ??= contentType.get();
    }

    /// Get the license
    if (newPackageInfo.license == null) {
      final licenses = await BaNaNaS.bananas.getLicenses();
      final licenseIndex = Select(
        prompt: 'Which license?',
        options: licenses.map((l) => l.name).toList(),
      ).interact();
      newPackageInfo.license ??= licenses[licenseIndex].name;
    }

    /// Get the version
    if (newPackageInfo.version == null) {
      final version = Input(
        prompt: 'What version is this?',
        validator: emptyStringValidator,
      ).interact();
      newPackageInfo.version ??= version;
    }

    /// Get name of package
    if (newPackageInfo.name == null) {
      final name = Input(
        prompt: 'What should the name for this package be?',
        validator: emptyStringValidator,
      ).interact();
      newPackageInfo.name ??= name;
    }

    /// Get description of package.
    if (newPackageInfo.description == null) {
      final description = Input(
        prompt: 'What should the description of the package be?',
        validator: emptyStringValidator,
      ).interact();
      if (description.isNotEmpty) newPackageInfo.description ??= description;
    }

    /// Get the URL of the package.
    if (newPackageInfo.url == null) {
      final url = Input(
        prompt: 'What is the URL of the package?',
        validator: (String value) {
          /// We'll use a regex string to validate if this is infact a URL.
          /// See https://stackoverflow.com/questions/3809401/what-is-a-good-regular-expression-to-match-a-url
          final regex = RegExp(r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)', caseSensitive: false);
          if (regex.hasMatch(value)) {
            return true;
          } else {
            throw ValidationError('This has to be a valid URL.');
          }
        },
      ).interact();
      if (url.isNotEmpty) newPackageInfo.url ??= url;
    }

    // Confirm this package.
    final uploadConfirmed = Confirm(
      prompt: 'Are you sure you want to publish ${newPackageInfo.name}, ${newPackageInfo.version}? ' + '(Note: Publishing is forever!)'.gray(),
      defaultValue: true,
      waitForNewLine: true,
    ).interact();

    if (!uploadConfirmed) return;

    await BaNaNaS.bananas.updatePackageInfo(uploadToken, newPackageInfo);

    /// Prepare for file upload.
    final tusd = TusdClient(
      uploadToken: uploadToken,
      uri: Uri.https(tusBase, '/new-package/tus/'), 
      file: file, 
      headers: {

      }
    );
    await tusd.prepare();

    final uploadProgress = Spinner(
      icon: '',
      leftPrompt: (done) => done ? '✔'.padRight(2).green() + 'Finished uploading file!' : '✘'.padRight(2).red() + 'Uploading...'
    ).interact();

    await tusd.upload(onProgress: (progress) {

    }, onComplete: () {
      uploadProgress.done();
    });

    try {
      await BaNaNaS.bananas.publishNewPackage(uploadToken);
      print('✔'.padRight(2).green() + 'Published successfully!'.bold());
    } on PackageException catch (e) {
      for (final error in e.errors) {
        print(error);
      }
      print(('✘'.padRight(2) + 'Publishing failed!'.bold()).red());
    }
  }
}