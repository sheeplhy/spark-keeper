import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'message_template.dart';

class TemplateStore {
  TemplateStore({this._preferences});
  static const _key = 'templates.items';
  final SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? SharedPreferences.getInstance();

  Future<List<MessageTemplate>> load() async {
    final raw = (await _prefs).getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(MessageTemplate.fromJson)
        .toList();
  }

  Future<void> save(List<MessageTemplate> items) async {
    await (await _prefs).setString(
      _key,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }
}
