class ApiConfig {
  // Android emulator reaches the host machine via 10.0.2.2
  // iOS simulator reaches it via localhost
  static const String prodBaseUrl = 'https://api.ibogha241.ga';

  static String get baseUrl => prodBaseUrl;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
