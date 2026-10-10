import '../friends/spark_friend.dart';
import 'spark_plan.dart';

class AgentTaskConfig {
  static Map<String, Object?> build(SparkPlan plan, List<SparkFriend> friends) {
    final byId = {for (final friend in friends) friend.id: friend};
    final selected = plan.friendIds
        .map((id) => byId[id])
        .whereType<SparkFriend>()
        .where((friend) => friend.enabled)
        .toList();
    final choices = [
      for (final content in plan.messages) {'type': 'text', 'content': content},
    ];
    return {
      'timezone': 'Asia/Shanghai',
      'task_id': plan.id,
      'targets': [
        for (final friend in selected)
          {
            'name': friend.nickname,
            'messages': plan.mode == PlanMessageMode.random
                ? [
                    {'type': 'random', 'choices': choices},
                  ]
                : choices,
          },
      ],
      'send_interval_seconds': {'min': 5, 'max': 12},
      'continue_on_error': true,
      'prevent_duplicates': true,
      'target_open_retries': 1,
      'target_open_timeout_seconds': 15,
    };
  }
}
