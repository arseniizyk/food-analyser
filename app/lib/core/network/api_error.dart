class ApiError implements Exception {
  const ApiError(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;

  /// The underlying error (connection failure, timeout, parse error, ...).
  final Object? cause;

  @override
  String toString() {
    return message;
  }
}
