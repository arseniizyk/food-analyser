class Env {
  const Env._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const ocrServiceUrl = String.fromEnvironment(
    'OCR_SERVICE_URL',
    defaultValue: 'http://localhost:8000',
  );
}
