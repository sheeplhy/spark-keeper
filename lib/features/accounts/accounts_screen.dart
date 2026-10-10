import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../ui/core/page_header.dart';
import '../../ui/core/status_pill.dart';

class AccountSummary {
  const AccountSummary({
    required this.name,
    required this.runtime,
    required this.status,
    required this.tone,
    required this.icon,
  });

  final String name;
  final String runtime;
  final String status;
  final StatusTone tone;
  final IconData icon;
}

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  static const _accounts = [
    AccountSummary(
      name: '小火花',
      runtime: '我的电脑 · 2 分钟前检查',
      status: '已登录',
      tone: StatusTone.success,
      icon: Icons.person_rounded,
    ),
    AccountSummary(
      name: '内容号',
      runtime: '我的电脑 · 等待人工处理',
      status: '需要登录',
      tone: StatusTone.warning,
      icon: Icons.face_rounded,
    ),
    AccountSummary(
      name: '测试账号',
      runtime: '云端服务器 · 10 分钟前检查',
      status: '状态未知',
      tone: StatusTone.neutral,
      icon: Icons.science_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          PageHeader(
            title: '账号',
            subtitle: '每个账号使用独立会话与状态',
            trailing: IconButton.filled(
              tooltip: '添加账号',
              onPressed: () => _showAddMessage(context),
              icon: const Icon(Icons.add_rounded),
            ),
          ),
          const SizedBox(height: 20),
          for (final account in _accounts) ...[
            _AccountCard(account: account),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  void _showAddMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('下一课会实现添加账号表单'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account});

  final AccountSummary account;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.16),
              foregroundColor: AppColors.secondary,
              child: Icon(account.icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    account.runtime,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StatusPill(
                    label: account.status,
                    icon: Icons.circle,
                    tone: account.tone,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: '更多操作',
              onPressed: () {},
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
