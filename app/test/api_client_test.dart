import 'dart:convert';
import 'dart:io';

import 'package:app/core/network/api_client.dart';
import 'package:app/core/network/api_error.dart';
import 'package:app/core/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _analysisJson = {
  'barcode': '460000000001',
  'score': 85,
  'grade': 'good',
  'summary': [
    {'message': 'Low sugar content'},
  ],
  'risks': [
    {
      'severity': 'high',
      'title': 'E-numbers',
      'description': 'Contains colorants.',
    },
  ],
  'ingredients': [
    {
      'name': 'Sugar',
      'risk': 'caution',
      'description': 'High intake risk.',
    },
  ],
};

void main() {
  late MemorySecureStorage storage;

  setUp(() {
    storage = MemorySecureStorage();
  });

  HttpApiClient clientWith(MockClient mock) {
    return HttpApiClient(
      baseUrl: 'https://api.example.com',
      secureStorage: storage,
      client: mock,
    );
  }

  group('getAnalysisByBarcode', () {
    test('returns parsed analysis on 200', () async {
      final client = clientWith(
        MockClient((request) async {
          expect(request.url.path, '/api/v1/analysis/460000000001');
          return http.Response(jsonEncode(_analysisJson), 200);
        }),
      );

      final result = await client.getAnalysisByBarcode('460000000001');
      expect(result?['barcode'], '460000000001');
      expect(result?['grade'], 'good');
    });

    test('returns null on 404', () async {
      final client = clientWith(
        MockClient(
          (request) async => http.Response('{"message":"not found"}', 404),
        ),
      );

      expect(await client.getAnalysisByBarcode('460000000001'), isNull);
    });

    test('surfaces server error message from body', () async {
      final client = clientWith(
        MockClient(
          (request) async => http.Response(
            jsonEncode({'message': 'Internal Server Error'}),
            500,
          ),
        ),
      );

      await expectLater(
        client.getAnalysisByBarcode('460000000001'),
        throwsA(
          isA<ApiError>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', 'Internal Server Error'),
        ),
      );
    });

    test('falls back to generic message when body has none', () async {
      final client = clientWith(
        MockClient((request) async => http.Response('oops', 500)),
      );

      await expectLater(
        client.getAnalysisByBarcode('460000000001'),
        throwsA(
          isA<ApiError>().having(
            (e) => e.message,
            'message',
            'Не удалось получить результат анализа',
          ),
        ),
      );
    });

    test('wraps transport errors with the original cause', () async {
      final client = clientWith(
        MockClient((request) async => throw http.ClientException('refused')),
      );

      await expectLater(
        client.getAnalysisByBarcode('460000000001'),
        throwsA(
          isA<ApiError>()
              .having(
                (e) => e.message,
                'message',
                'Не удалось получить результат анализа',
              )
              .having((e) => e.cause, 'cause', isA<http.ClientException>()),
        ),
      );
    });

    test('sends Bearer token when one is stored', () async {
      await storage.write('access_token', 'token-123');
      late http.Request captured;
      final client = clientWith(
        MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode(_analysisJson), 200);
        }),
      );

      await client.getAnalysisByBarcode('460000000001');

      expect(captured.headers['Authorization'], 'Bearer token-123');
    });

    test('does not send Authorization header when token is absent', () async {
      late http.Request captured;
      final client = clientWith(
        MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode(_analysisJson), 200);
        }),
      );

      await client.getAnalysisByBarcode('460000000001');

      expect(captured.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('getHistory', () {
    test('returns decoded list', () async {
      final client = clientWith(
        MockClient(
          (request) async => http.Response(
            jsonEncode([_analysisJson, _analysisJson]),
            200,
          ),
        ),
      );

      final result = await client.getHistory();
      expect(result, hasLength(2));
    });

    test('throws ApiError for non-list body', () async {
      final client = clientWith(
        MockClient((request) async => http.Response('{"barcode":"x"}', 200)),
      );

      await expectLater(
        client.getHistory(),
        throwsA(isA<ApiError>()),
      );
    });

    test('wraps transport errors with the original cause', () async {
      final client = clientWith(
        MockClient((request) async => throw http.ClientException('refused')),
      );

      await expectLater(
        client.getHistory(),
        throwsA(
          isA<ApiError>()
              .having((e) => e.message, 'message', 'Не удалось получить историю')
              .having((e) => e.cause, 'cause', isA<http.ClientException>()),
        ),
      );
    });
  });

  group('analyze', () {
    test('fails with cause when image file does not exist', () async {
      final client = clientWith(
        MockClient(
          (request) async => http.Response('{}', 200),
        ),
      );

      await expectLater(
        client.analyze(
          barcode: '460000000001',
          imagePath: '/does/not/exist.jpg',
        ),
        throwsA(
          isA<ApiError>().having(
            (e) => e.cause,
            'cause',
            isA<FileSystemException>(),
          ),
        ),
      );
    });
  });
}