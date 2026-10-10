import 'package:shared_preferences/shared_preferences.dart';

class DesktopAgentSettings {
  const DesktopAgentSettings({required this.baseUrl, required this.token});
  final String baseUrl;
  final String token;
}

class DesktopAgentSettingsStore {
  DesktopAgentSettingsStore({this._preferences});

  static const _baseUrlKey = 'agent.baseUrl';
  static const _tokenKey = 'agent.token';
  final SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? SharedPreferences.getInstance();

  Future<DesktopAgentSettings?> load() async {
    final preferences = await _prefs;
    final baseUrl = preferences.getString(_baseUrlKey)?.trim() ?? '';
    final token = preferences.getString(_tokenKey)?.trim() ?? '';
    if (baseUrl.isEmpty || token.isEmpty) return null;
    return DesktopAgentSettings(baseUrl: baseUrl, token: token);
  }

  Future<void> save(DesktopAgentSettings settings) async {
    final preferences = await _prefs;
    await preferences.setString(_baseUrlKey, settings.baseUrl.trim());
    await preferences.setString(_tokenKey, settings.token.trim());
  }

  Future<void> clear() async {
    final preferences = await _prefs;
    await preferences.remove(_baseUrlKey);
    await preferences.remove(_tokenKey);
  }
}
