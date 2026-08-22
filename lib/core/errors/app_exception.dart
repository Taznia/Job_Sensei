class AppException implements Exception {
  AppException(
    this.message, {
    this.isNetwork = false,
    this.statusCode,
  });

  final String message;
  final bool isNetwork;
  final int? statusCode;

  @override
  String toString() => message;
}
