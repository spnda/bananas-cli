import 'dart:io';

import 'package:crypto/crypto.dart';

Future<String> getMd5sumOfFile(File file) async {
  if (await file.exists()) {
    return (await md5.bind(file.openRead()).first).toString();
  } else {
    throw ArgumentError.value(file, 'file', 'File must exist.');
  }
}
