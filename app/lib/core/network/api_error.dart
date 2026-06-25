class ApiError implements Exception {
  const ApiError(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' [$statusCode]';
    return '$message$code';
  }
}
