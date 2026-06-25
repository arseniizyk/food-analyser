class Env {
  const Env._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.food-analyzer.local',
  );

  static const ocrServiceUrl = String.fromEnvironment(
    'OCR_SERVICE_URL',
    defaultValue: 'http://192.168.3.28:8000',
  );
}
