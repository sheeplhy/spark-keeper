import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_settings_store.dart';

class ApiConnectionResult {
  const ApiConnectionResult({
    required this.isSuccess,
    required this.message,
    this.latency,
  });

  final bool isSuccess;
  final String message;
  final Duration? latency;
}

class ApiConnectionService {
  ApiConnectionService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<ApiConnectionResult> test(ApiSettingsData settings) async {
    final endpoint = Uri.parse(
      '${settings.baseUrl.trim().replaceFirst(RegExp(r'/+$'), '')}/chat/completions',
    );
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _client
          .post(
            endpoint,
            headers: {
              'Authorization': 'Bearer ${settings.apiKey.trim()}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': settings.model.trim(),
              'messages': [
                {'role': 'user', 'content': 'Reply with OK.'},
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));
      stopwatch.stop();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiConnectionResult(
          isSuccess: true,
          message: '连接成功，API 可以正常使用',
          latency: stopwatch.elapsed,
        );
      }

      return ApiConnectionResult(
        isSuccess: false,
        message: _errorMessage(response),
        latency: stopwatch.elapsed,
      );
    } on TimeoutException {
      return const ApiConnectionResult(
        isSuccess: false,
        message: '连接超时，请检查网络或 API 地址',
      );
    } on FormatException {
      return const ApiConnectionResult(
        isSuccess: false,
        message: 'API 地址格式不正确',
      );
    } on http.ClientException catch (error) {
      return ApiConnectionResult(
        isSuccess: false,
        message: '网络请求失败：${error.message}。Web 版还需确认服务商允许浏览器跨域访问。',
      );
    } catch (error) {
      return ApiConnectionResult(isSuccess: false, message: '连接失败：$error');
    }
  }

  String _errorMessage(http.Response response) {
    final serverMessage = _readServerMessage(response.body);
    final detail = serverMessage == null ? '' : '：$serverMessage';

    return switch (response.statusCode) {
      401 => 'API Key 无效或已失效$detail',
      403 => '当前 API Key 没有访问权限$detail',
      404 => 'API 地址或模型名称不存在$detail',
      429 => '请求过于频繁或账户额度不足$detail',
      _ => '服务商返回错误 ${response.statusCode}$detail',
    };
  }

  String? _readServerMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final error = decoded['error'];
      final message = error is Map<String, dynamic>
          ? error['message']
          : decoded['message'];
      if (message is! String || message.trim().isEmpty) return null;
      final normalized = message.trim();
      return normalized.length <= 160
          ? normalized
          : '${normalized.substring(0, 160)}…';
    } catch (_) {
      return null;
    }
  }

  void close() => _client.close();
}
