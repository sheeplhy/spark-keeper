import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:spark_keeper/features/settings/api_connection_service.dart';
import 'package:spark_keeper/features/settings/api_settings_store.dart';

void main() {
  const settings = ApiSettingsData(
    provider: ApiProvider.openAiCompatible,
    baseUrl: 'https://api.example.com/v1/',
    apiKey: 'user-test-key',
    model: 'test-model',
  );

  test('sends a compatible chat completion request', () async {
    final service = ApiConnectionService(
      client: MockClient((request) async {
        expect(
          request.url.toString(),
          'https://api.example.com/v1/chat/completions',
        );
        expect(request.headers['authorization'], 'Bearer user-test-key');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['model'], 'test-model');
        return http.Response('{"choices":[]}', 200);
      }),
    );

    final result = await service.test(settings);

    expect(result.isSuccess, isTrue);
    expect(result.message, contains('连接成功'));
    service.close();
  });

  test('returns an understandable message for an invalid key', () async {
    final service = ApiConnectionService(
      client: MockClient(
        (_) async =>
            http.Response('{"error":{"message":"Incorrect API key"}}', 401),
      ),
    );

    final result = await service.test(settings);

    expect(result.isSuccess, isFalse);
    expect(result.message, contains('API Key 无效'));
    service.close();
  });
}
