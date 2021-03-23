import 'dart:io';

String getApplicationDataDirectory() {
  if (Platform.isMacOS || Platform.isLinux) {
    return Platform.environment['HOME'] ?? Directory.current.path;
  } else if (Platform.isWindows) {
    return Platform.environment['APPDATA'] ?? Directory.current.path;
  } else {
    return Directory.current.path;
  }
}
