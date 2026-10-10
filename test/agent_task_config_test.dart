import 'package:flutter_test/flutter_test.dart';
import 'package:spark_keeper/features/friends/spark_friend.dart';
import 'package:spark_keeper/features/plans/agent_task_config.dart';
import 'package:spark_keeper/features/plans/spark_plan.dart';

void main() {
  const friends = [
    SparkFriend(id: '1', nickname: '小明'),
    SparkFriend(id: '2', nickname: '已暂停', enabled: false),
  ];

  test('builds a random message task and excludes disabled friends', () {
    const plan = SparkPlan(
      id: 'daily',
      name: '每日续火花',
      friendIds: ['1', '2'],
      mode: PlanMessageMode.random,
      messages: ['你好 🔥', '今天开心'],
      hour: 20,
      minute: 0,
    );

    final config = AgentTaskConfig.build(plan, friends);
    final targets = config['targets'] as List<Object?>;
    expect(targets, hasLength(1));
    final target = targets.single as Map<String, Object?>;
    expect(target['name'], '小明');
    final messages = target['messages'] as List<Object?>;
    expect((messages.single as Map<String, Object?>)['type'], 'random');
    expect(config['prevent_duplicates'], isTrue);
  });

  test('custom mode sends each line in order', () {
    const plan = SparkPlan(
      id: 'custom',
      name: '自定义',
      friendIds: ['1'],
      mode: PlanMessageMode.custom,
      messages: ['第一条', '第二条'],
      hour: 8,
      minute: 30,
    );

    final config = AgentTaskConfig.build(plan, friends);
    final target =
        (config['targets'] as List<Object?>).single as Map<String, Object?>;
    final messages = target['messages'] as List<Object?>;
    expect(messages, hasLength(2));
    expect((messages.first as Map<String, Object?>)['content'], '第一条');
  });
}
