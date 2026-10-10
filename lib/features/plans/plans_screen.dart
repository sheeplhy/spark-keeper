import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../ui/core/empty_state_panel.dart';
import '../../ui/core/page_header.dart';
import '../connection/desktop_agent_client.dart';
import '../friends/friend_store.dart';
import '../friends/spark_friend.dart';
import 'agent_task_config.dart';
import 'plan_store.dart';
import 'spark_plan.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});
  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  final _store = PlanStore();
  final _friendStore = FriendStore();
  List<SparkPlan> _plans = const [];
  List<SparkFriend> _friends = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans = await _store.load();
    final friends = await _friendStore.load();
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _friends = friends;
      _loading = false;
    });
  }

  Future<void> _save(List<SparkPlan> plans) async {
    setState(() => _plans = plans);
    await _store.save(plans);
  }

  Future<void> _addPlan() async {
    await _load();
    if (!mounted) return;
    final enabledFriends = _friends.where((friend) => friend.enabled).toList();
    if (enabledFriends.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先到“好友”页添加并启用好友')));
      return;
    }
    final plan = await Navigator.of(context).push<SparkPlan>(
      MaterialPageRoute(builder: (_) => _PlanEditor(friends: enabledFriends)),
    );
    if (plan != null) await _save([..._plans, plan]);
  }

  Future<void> _sync(SparkPlan plan, {required bool dryRun}) async {
    try {
      final client = await DesktopAgentClient.fromSavedSettings();
      if (client == null) throw const AgentException('请先在首页连接电脑 Agent');
      final config = AgentTaskConfig.build(plan, _friends);
      if ((config['targets'] as List<Object?>).isEmpty) {
        throw const AgentException('计划中没有可用好友');
      }
      await client.saveTask(config);
      if (dryRun) {
        await client.runDry();
      } else {
        await client.run();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(dryRun ? '已在电脑开始检查，不会发送消息' : '已在电脑开始执行计划')),
      );
    } on AgentException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _schedule(SparkPlan plan) async {
    try {
      final client = await DesktopAgentClient.fromSavedSettings();
      if (client == null) throw const AgentException('请先在首页连接电脑 Agent');
      final config = AgentTaskConfig.build(plan, _friends);
      if ((config['targets'] as List<Object?>).isEmpty) {
        throw const AgentException('计划中没有可用好友');
      }
      await client.saveSchedule({
        'id': plan.id,
        'name': plan.name,
        'enabled': plan.enabled,
        'hour': plan.hour,
        'minute': plan.minute,
        'task': config,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('定时计划已同步到电脑；手机退出后仍会执行')));
    } on AgentException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _remove(SparkPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除计划？'),
        content: Text('将删除“${plan.name}”。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _save(_plans.where((item) => item.id != plan.id).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            PageHeader(
              title: '续火花计划',
              subtitle: '先检查，再启用正式发送',
              trailing: IconButton.filled(
                tooltip: '添加计划',
                onPressed: _addPlan,
                icon: const Icon(Icons.add_rounded),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_plans.isEmpty)
              EmptyStatePanel(
                icon: Icons.calendar_month_outlined,
                title: '暂无续火花计划',
                description: '选择好友、消息和时间后同步到电脑',
                actionLabel: '添加计划',
                onAction: _addPlan,
              )
            else
              for (final plan in _plans) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                plan.name,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Switch(
                              value: plan.enabled,
                              onChanged: (enabled) => _save([
                                for (final item in _plans)
                                  if (item.id == plan.id)
                                    item.copyWith(enabled: enabled)
                                  else
                                    item,
                              ]),
                            ),
                            IconButton(
                              tooltip: '删除',
                              onPressed: () => _remove(plan),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            onPressed: () => _schedule(plan),
                            icon: const Icon(Icons.sync_rounded),
                            label: const Text('同步自动计划到电脑'),
                          ),
                        ),
                        Text(
                          '${plan.friendIds.length} 位好友 · ${plan.mode == PlanMessageMode.random ? '随机一条' : '顺序发送'} · ${plan.hour.toString().padLeft(2, '0')}:${plan.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _sync(plan, dryRun: true),
                                icon: const Icon(Icons.fact_check_outlined),
                                label: const Text('检查任务'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: plan.enabled
                                    ? () => _sync(plan, dryRun: false)
                                    : null,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('立即执行'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _PlanEditor extends StatefulWidget {
  const _PlanEditor({required this.friends});
  final List<SparkFriend> friends;
  @override
  State<_PlanEditor> createState() => _PlanEditorState();
}

class _PlanEditorState extends State<_PlanEditor> {
  final _name = TextEditingController(text: '每日续火花');
  final _messages = TextEditingController(text: '来续火花啦 🔥\n今天也要开心呀 😊\n记得按时吃饭');
  final Set<String> _selected = {};
  PlanMessageMode _mode = PlanMessageMode.random;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);

  @override
  void dispose() {
    _name.dispose();
    _messages.dispose();
    super.dispose();
  }

  void _submit() {
    final messages = _messages.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    if (_name.text.trim().isEmpty || _selected.isEmpty || messages.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请填写计划名称、选择好友并输入至少一条消息')));
      return;
    }
    Navigator.pop(
      context,
      SparkPlan(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        friendIds: _selected.toList(),
        mode: _mode,
        messages: messages,
        hour: _time.hour,
        minute: _time.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新建计划')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: '计划名称'),
          ),
          const SizedBox(height: 16),
          Text(
            '选择好友',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final friend in widget.friends)
            CheckboxListTile(
              value: _selected.contains(friend.id),
              title: Text(friend.nickname),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (selected) => setState(() {
                if (selected == true) {
                  _selected.add(friend.id);
                } else {
                  _selected.remove(friend.id);
                }
              }),
            ),
          const SizedBox(height: 12),
          SegmentedButton<PlanMessageMode>(
            segments: const [
              ButtonSegment(
                value: PlanMessageMode.random,
                icon: Icon(Icons.shuffle_rounded),
                label: Text('随机一条'),
              ),
              ButtonSegment(
                value: PlanMessageMode.custom,
                icon: Icon(Icons.list_alt_rounded),
                label: Text('顺序发送'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (value) => setState(() => _mode = value.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _messages,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: '消息（每行一条，可含 Emoji）',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.outline),
            ),
            leading: const Icon(Icons.schedule_rounded),
            title: const Text('计划时间'),
            trailing: Text(_time.format(context)),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _time,
              );
              if (time != null) setState(() => _time = time);
            },
          ),
          const SizedBox(height: 12),
          const Text(
            '保存后同步到电脑 Agent。电脑必须在线且已登录；正式发送前建议先点“检查任务”。',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(onPressed: _submit, child: const Text('保存计划')),
        ],
      ),
    );
  }
}
