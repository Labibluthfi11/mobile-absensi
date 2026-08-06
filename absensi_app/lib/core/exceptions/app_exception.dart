class AppException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  AppException({
    required this.message,
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() => 'AppException(message: $message, statusCode: $statusCode, isNetworkError: $isNetworkError)';
}
