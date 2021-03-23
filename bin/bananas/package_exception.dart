class PackageException implements Exception {
  final String message;
  final List<String> errors;

  PackageException(this.message, this.errors);
}
