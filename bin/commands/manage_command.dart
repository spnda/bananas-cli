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
import '../utilities/inputVerifiers.dart';
import '../utilities/md5sum.dart';

class ManageCommand extends Command {
  @override
  String get description => 'Command to manage packages.';

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

    final optionText = ['Upload new package', 'Update a package', 'Edit a package'];
    final options = ['new', 'update', 'edit'];
    final chosenOption = Select(
      prompt: 'What do you want to do?', 
      options: optionText
    ).interact();

    switch (options[chosenOption]) {
      case 'edit':
        await editPackage();
        break;
      case 'new':
        await uploadNew();
        break;
      case 'update':
        await updatePackage();
        break;
      default:
        throw Exception('Unknown option.');
    }
  }

  Package _askWhichPackage() {
    final chosenPackage = Select(
      prompt: 'Which package do you want to edit?',
      options: myPackages.map((p) => '${p.name} ' + '(${p.uniqueId})'.gray()).toList().cast<String>(),
    ).interact();
    return myPackages[chosenPackage];
  }

  Future<File> _showFilePrompt() async {
    /// Give the user a list of all files in the current directory to choose from.
    /// This might be subject to change, so that we have a more dynamic system.
    final filesInDirectory = Directory.current.listSync();
    final chosenFile = Select(
      prompt: 'Which file do you want to upload?',
      options: filesInDirectory.map((f) => basename(f.path)).toList(),
    ).interact();
    return File(filesInDirectory[chosenFile].path);
  }

  /// Edit a package interactively. Can only edit global package information, not version information.
  Future<void> editPackage() async {
    final package = _askWhichPackage();
    
    /// Allow the user to change any values of the [package] object.
    var exit = false;
    while(!exit) {
      const fields = ['name', 'description', 'url', 'tags', 'Done, save'];
      final chosenFieldToEdit = Select(
        prompt: 'Which value do you want to edit?',
        options: fields,
      ).interact();
      
      /// If they selected 'Done, save', we'll exit this loop and send the new data to the API.
      if (chosenFieldToEdit == fields.length - 1) {
        exit = true;
        break;
      }

      switch (fields[chosenFieldToEdit]) {
        case 'name':
          var newName = Input(
            prompt: 'Enter a new name:',
            validator: emptyStringValidator,
          ).interact();
          package.name = newName;
          break;
        case 'description':
          var newDescription = Input(
            prompt: 'Enter a new description:',
            validator: emptyStringValidator,
          ).interact();
          package.description = newDescription.replaceAll('\\n', '\n');
          break;
        case 'url':
          var newUrl = Input(
            prompt: 'Enter a new URL:',
            validator: urlStringValidator,
          ).interact();
          package.url = newUrl;
          break;
        case 'tags':
          var newTags = Input(
            prompt: 'Add new tags: ' + '(Comma seperated!)'.gray(),
            validator: stringListValidator,
          ).interact();
          package.tags.clear();
          package.tags.addAll(newTags.split(',').map((s) => s.trim()).toList());
          break;
      }
    }

    final confirmed = Confirm(
      prompt: 'Are you sure you want to save this new information? ' + '(Note: Old information will be overriden and lost)'.gray(),
      defaultValue: true,
      waitForNewLine: true,
    ).interact();
    if (confirmed) {
      await BaNaNaS.bananas.updateGlobalPackageInfo(package);
      print('✔'.padRight(2).green() + 'Successfully updated new info.'.bold());
    } else {
      return;
    }
  }

  /// Method to upload a new package, and a new package only.
  Future<void> uploadNew() async {
    final file = await _showFilePrompt();

    final md5sum = await getMd5sumOfFile(file);
    for (final package in myPackages) {
      /// This might not work, as for example with NewGRFs, the md5sum on the server
      /// ignores the sprites. Therefore, md5sums might vary but we'll still check for 
      /// them anyway *just in case*.
      if (package.versions.first.md5sumPartial == md5sum.substring(md5sum.length - 9)) {
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

    /// Get the content type.
    if (newPackageInfo.contentType == null) {
      final contentTypeIndex = Select(
        prompt: 'What content type is this package?',
        options: BananasContentType.values.map((t) => t.getHumanReadable()).where((t) => t.isNotEmpty).toList(),
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
        validator: urlStringValidator,
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

  Future<void> updatePackage() async {
    final package = _askWhichPackage();

    /// Get the file upload token & info.
    final uploadToken = await BaNaNaS.bananas.newPackage();
    var newPackageInfo = await BaNaNaS.bananas.getNewPackageInfo(uploadToken);
    /// Copy values over so that it notices the 'update' of a existing package.
    newPackageInfo.name = package.name;
    // newPackageInfo.uniqueId = package.uniqueId;
    newPackageInfo.description = package.description;
    
    /// Get the version
    if (newPackageInfo.version == null) {
      final version = Input(
        prompt: 'What version are you updating to?',
        validator: emptyStringValidator,
      ).interact();
      newPackageInfo.version ??= version;
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

    /// Update the package info for our upload.
    await BaNaNaS.bananas.updatePackageInfo(uploadToken, newPackageInfo);

    /// Get the file and the tusd client.
    final file = await _showFilePrompt();
    final tusd = TusdClient(
      uploadToken: uploadToken,
      uri: Uri.https(tusBase, '/new-package/tus/'),
      file: file,
      headers: {},
    );
    await tusd.prepare();
    await tusd.upload(onProgress: (progress) {}, onComplete: () {});

    /// Get the updated package info after uploading the file
    /// This also includes the md5sum-partial and unique-id, allowing
    /// us to check if this GRF has been uploaded elsewhere.
    /// This command is purely for update purposes, so that if we do find
    /// that the GRFID is different to the one selected before, we error.
    var updatedPackageInfo = await BaNaNaS.bananas.getNewPackageInfo(uploadToken);
    if (updatedPackageInfo.uniqueId != package.uniqueId) {
      print(('✘'.padRight(2) + 'The selected GRF file does not have the same GRFID as the previous versions of the package. We do not allow uploading GRFs with different GRFIDs as the same package.'.bold()).red());
      return;
    }

    try {
      await BaNaNaS.bananas.publishNewPackage(uploadToken);
      print('✔'.padRight(2).green() + 'Published successfully!'.bold());
    } on PackageException catch (e) {
      for (final error in e.errors) {
        print(('✘'.padRight(2) + error.bold()).red());
      }
      print(('✘'.padRight(2) + 'Publishing failed!'.bold()).red());
      exit(0); /// Force close the program, it sometimes hangs on close.
    }
  }
}
