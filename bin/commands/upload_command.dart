import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:interact/interact.dart';
import 'package:tint/tint.dart';

import '../bananas/bananas.dart';
import '../bananas/bananas_url.dart';
import '../bananas/content_type.dart';
import '../bananas/package_exception.dart';
import '../bananas/tusd/tusd_client.dart';
import '../github/github_auth.dart';

class UploadCommand extends Command {
  @override
  String get description => 'Uploads and publishes a GRF to BaNaNaS.';

  @override
  String get name => 'upload';

  UploadCommand() {
    // Add more options?
  }

  @override
  void run() async {
    if (argResults == null) return;
    var file;
    try {
      file = File(argResults!.rest.first);
      if (!(await file.exists())) throw Error();
    } on Error {
      throw UsageException('Did not specify file.', 'upload <file>');
    }

    final auth = GitHubAuth('ape');
    try {
      await auth.init();
    } on Exception {
      return;
    }

    final uploadToken = await BaNaNaS.bananas.newPackage();
    var newPackageInfo = await BaNaNaS.bananas.getNewPackageInfo(uploadToken);

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
      ).interact();
      newPackageInfo.version ??= version;
    }

    /// Get name of package
    if (newPackageInfo.name == null) {
      final name = Input(
        prompt: 'What should the name for this package be?',
      ).interact();
      newPackageInfo.name ??= name;
    }

    /// Get description of package.
    if (newPackageInfo.description == null) {
      final description = Input(
        prompt: 'What should the description of the package be?'
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
          return regex.hasMatch(value);
        },
      ).interact();
      if (url.isNotEmpty) newPackageInfo.url ??= url;
    }

    // Confirm this package.
    final uploadConfirmed = Confirm(
      prompt: 'Are you sure you want to publish ${newPackageInfo.name}, ${newPackageInfo.version}?',
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
