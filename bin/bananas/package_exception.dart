/// When a package fails to validate while publishing.
class PackageException implements Exception {
  final String message;
  final List<String> errors;

  PackageException(this.message, this.errors);
}
