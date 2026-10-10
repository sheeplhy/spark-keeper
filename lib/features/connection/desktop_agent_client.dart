import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'desktop_agent_settings.dart';

class AgentException implements Exception {
  const AgentException(this.message);
  final String message;
  @override
  String toString() => message;
}

class DesktopAgentClient {
  DesktopAgentClient(this.settings, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final DesktopAgentSettings settings;
  final http.Client _http;

  static Future<DesktopAgentClient?> fromSavedSettings() async {
    final settings = await DesktopAgentSettingsStore().load();
    return settings == null ? null : DesktopAgentClient(settings);
  }

  Uri _uri(String path) {
    final normalized = settings.baseUrl.endsWith('/')
        ? settings.baseUrl.substring(0, settings.baseUrl.length - 1)
        : settings.baseUrl;
    return Uri.parse('$normalized$path');
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${settings.token}',
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> health() =>
      _get('/health', authenticated: false);
  Future<Map<String, dynamic>> status() => _get('/status');
  Future<Map<String, dynamic>> loginStatus() => _get('/login/status');
  Future<Map<String, dynamic>> result() => _get('/result');
  Future<Map<String, dynamic>> startLogin() => _post('/login');
  Future<Map<String, dynamic>> runDry() => _post('/run/dry');
  Future<Map<String, dynamic>> run() => _post('/run');
  Future<Map<String, dynamic>> saveTask(Map<String, Object?> task) =>
      _post('/task', task);
  Future<Map<String, dynamic>> saveSchedule(Map<String, Object?> schedule) =>
      _post('/schedule', schedule);

  Future<Uint8List?> loginQr() async {
    try {
      final response = await _http.get(_uri('/login/qr'), headers: _headers);
      if (response.statusCode == 404) return null;
      _ensureSuccess(response);
      return response.bodyBytes;
    } catch (error) {
      if (error is AgentException) rethrow;
      throw AgentException('无法读取登录二维码：$error');
    }
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    bool authenticated = true,
  }) async {
    try {
      final response = await _http.get(
        _uri(path),
        headers: authenticated ? _headers : null,
      );
      _ensureSuccess(response);
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (error) {
      if (error is AgentException) rethrow;
      throw AgentException('连接电脑失败，请确认同一 Wi‑Fi、地址和防火墙：$error');
    }
  }

  Future<Map<String, dynamic>> _post(
    String path, [
    Map<String, Object?>? body,
  ]) async {
    try {
      final response = await _http.post(
        _uri(path),
        headers: _headers,
        body: body == null ? null : jsonEncode(body),
      );
      _ensureSuccess(response);
      return jsonDecode(utf8.decode(response.bodyBytes))
          as Map<String, dynamic>;
    } catch (error) {
      if (error is AgentException) rethrow;
      throw AgentException('操作失败：$error');
    }
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    var message = '电脑 Agent 返回 ${response.statusCode}';
    try {
      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      message = body['error'] as String? ?? message;
    } catch (_) {}
    throw AgentException(message);
  }
}
