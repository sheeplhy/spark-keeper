import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../ui/core/empty_state_panel.dart';
import '../../ui/core/page_header.dart';
import 'friend_store.dart';
import 'spark_friend.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _store = FriendStore();
  List<SparkFriend> _friends = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final friends = await _store.load();
    if (mounted) {
      setState(() {
        _friends = friends;
        _loading = false;
      });
    }
  }

  Future<void> _save(List<SparkFriend> friends) async {
    setState(() => _friends = friends);
    await _store.save(friends);
  }

  Future<void> _addFriend() async {
    final controller = TextEditingController();
    final nickname = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加好友'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(
            labelText: '抖音好友昵称',
            hintText: '请输入完整昵称',
            helperText: '需与抖音网页版私信搜索结果一致',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('添加'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (nickname == null || nickname.isEmpty || !mounted) return;
    if (_friends.any((friend) => friend.nickname == nickname)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('这个好友已经添加过了')));
      return;
    }
    await _save([
      ..._friends,
      SparkFriend(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        nickname: nickname,
      ),
    ]);
  }

  Future<void> _remove(SparkFriend friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除好友？'),
        content: Text('“${friend.nickname}”将同时从新计划的可选列表中移除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _save(_friends.where((item) => item.id != friend.id).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          PageHeader(
            title: '好友管理',
            subtitle: '数量不限，默认串行执行',
            trailing: IconButton.filled(
              tooltip: '添加好友',
              onPressed: _addFriend,
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '只保存好友昵称，不读取整份通讯录。首次运行请先“检查任务”，确认搜索到的是正确好友。',
                    style: TextStyle(
                      color: AppColors.muted,
                      height: 1.45,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
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
          else if (_friends.isEmpty)
            EmptyStatePanel(
              icon: Icons.group_add_outlined,
              title: '还没有好友',
              description: '填写抖音昵称后，就能在计划里选择',
              actionLabel: '添加第一个好友',
              onAction: _addFriend,
            )
          else
            for (final friend in _friends) ...[
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                    foregroundColor: AppColors.primary,
                    child: Text(friend.nickname.characters.first),
                  ),
                  title: Text(friend.nickname),
                  subtitle: Text(friend.enabled ? '可加入计划' : '已暂停'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: friend.enabled,
                        onChanged: (enabled) => _save([
                          for (final item in _friends)
                            if (item.id == friend.id)
                              item.copyWith(enabled: enabled)
                            else
                              item,
                        ]),
                      ),
                      IconButton(
                        tooltip: '移除',
                        onPressed: () => _remove(friend),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}
