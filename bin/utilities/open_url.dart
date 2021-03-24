import 'dart:io';

Future<ProcessResult> openUrl(String url) {
  return Process.run(_command, [url], runInShell: true);
}

String get _command {
  if (Platform.isWindows) {
    return 'start';
  } else if (Platform.isLinux) {
    return 'xdg-open';
  } else if (Platform.isMacOS) {
    return 'open';
  } else {
    throw UnsupportedError('Operating system not supported.');
  }
}
