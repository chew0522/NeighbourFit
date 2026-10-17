import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AI settings read from .env with defaults. Values are config, not constants.
class AiConfig {
  const AiConfig({
    required this.baseUrl,
    required this.model,
    required this.apiKey,
    required this.timeout,
  });

  final String baseUrl;
  final String model;
  final String apiKey;
  final Duration timeout;

  bool get hasKey => apiKey.trim().isNotEmpty;

  factory AiConfig.fromEnv() {
    String read(String key, String fallback) {
      try {
        final v = dotenv.maybeGet(key);
        return (v == null || v.trim().isEmpty) ? fallback : v.trim();
      } catch (_) {
        return fallback;
      }
    }

    return AiConfig(
      baseUrl: read('AI_BASE_URL', 'https://api.deepseek.com'),
      model: read('AI_MODEL', 'deepseek-chat'),
      apiKey: read('AI_API_KEY', ''),
      timeout: Duration(
        seconds: int.tryParse(read('AI_TIMEOUT_SECONDS', '8')) ?? 8,
      ),
    );
  }
}
