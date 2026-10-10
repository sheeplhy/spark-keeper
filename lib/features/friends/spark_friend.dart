class SparkFriend {
  const SparkFriend({
    required this.id,
    required this.nickname,
    this.enabled = true,
  });

  final String id;
  final String nickname;
  final bool enabled;

  SparkFriend copyWith({String? nickname, bool? enabled}) {
    return SparkFriend(
      id: id,
      nickname: nickname ?? this.nickname,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'nickname': nickname,
    'enabled': enabled,
  };

  factory SparkFriend.fromJson(Map<String, dynamic> json) {
    return SparkFriend(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
