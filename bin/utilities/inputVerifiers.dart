import 'package:interact/interact.dart';

bool emptyStringValidator(String value) {
  if (value.isEmpty) {
    throw ValidationError('This field cannot be empty.');
  } else {
    return true;
  }
}

bool urlStringValidator(String value) {
  /// We'll use a regex string to validate if this is infact a URL.
  /// See https://stackoverflow.com/questions/3809401/what-is-a-good-regular-expression-to-match-a-url
  final regex = RegExp(r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)', caseSensitive: false);
  if (regex.hasMatch(value)) {
    return true;
  } else {
    throw ValidationError('This has to be a valid URL.');
  }
}

bool stringListValidator(String value) {
  return true;
}
