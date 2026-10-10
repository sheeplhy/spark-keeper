import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'spark_friend.dart';

class FriendStore {
  FriendStore({this._preferences});

  static const _friendsKey = 'friends.items';

  final SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? SharedPreferences.getInstance();

  Future<List<SparkFriend>> load() async {
    final raw = (await _prefs).getString(_friendsKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(SparkFriend.fromJson)
        .toList();
  }

  Future<void> save(List<SparkFriend> friends) async {
    await (await _prefs).setString(
      _friendsKey,
      jsonEncode(friends.map((friend) => friend.toJson()).toList()),
    );
  }
}
