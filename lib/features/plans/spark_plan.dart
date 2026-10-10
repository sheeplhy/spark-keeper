enum PlanMessageMode { random, custom }

class SparkPlan {
  const SparkPlan({
    required this.id,
    required this.name,
    required this.friendIds,
    required this.mode,
    required this.messages,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  final String id;
  final String name;
  final List<String> friendIds;
  final PlanMessageMode mode;
  final List<String> messages;
  final int hour;
  final int minute;
  final bool enabled;

  SparkPlan copyWith({bool? enabled}) => SparkPlan(
    id: id,
    name: name,
    friendIds: friendIds,
    mode: mode,
    messages: messages,
    hour: hour,
    minute: minute,
    enabled: enabled ?? this.enabled,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'friendIds': friendIds,
    'mode': mode.name,
    'messages': messages,
    'hour': hour,
    'minute': minute,
    'enabled': enabled,
  };

  factory SparkPlan.fromJson(Map<String, dynamic> json) => SparkPlan(
    id: json['id'] as String,
    name: json['name'] as String,
    friendIds: List<String>.from(
      json['friendIds'] as List<dynamic>? ?? const [],
    ),
    mode: json['mode'] == 'custom'
        ? PlanMessageMode.custom
        : PlanMessageMode.random,
    messages: List<String>.from(json['messages'] as List<dynamic>? ?? const []),
    hour: json['hour'] as int? ?? 20,
    minute: json['minute'] as int? ?? 0,
    enabled: json['enabled'] as bool? ?? true,
  );
}
