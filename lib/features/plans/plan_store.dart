import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'spark_plan.dart';

class PlanStore {
  PlanStore({this._preferences});

  static const _key = 'plans.items';
  final SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? SharedPreferences.getInstance();

  Future<List<SparkPlan>> load() async {
    final raw = (await _prefs).getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(SparkPlan.fromJson)
        .toList();
  }

  Future<void> save(List<SparkPlan> plans) async {
    await (await _prefs).setString(
      _key,
      jsonEncode(plans.map((plan) => plan.toJson()).toList()),
    );
  }
}
