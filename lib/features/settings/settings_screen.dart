import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../connection/desktop_agent_screen.dart';
import '../templates/templates_screen.dart';
import 'about_screen.dart';
import 'api_settings_screen.dart';
import 'api_settings_store.dart';
import 'runtime_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _apiConfigured = false;

  @override
  void initState() {
    super.initState();
    _loadApiStatus();
  }

  Future<void> _loadApiStatus() async {
    try {
      final configured = await ApiSettingsStore().hasCompleteSettings();
      if (mounted) setState(() => _apiConfigured = configured);
    } catch (_) {
      // 在插件尚未就绪时保持“未配置”，不影响其他页面启动。
    }
  }

  Future<void> _openApiSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ApiSettingsScreen()));
    await _loadApiStatus();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          _ProfileCard(onTap: () {}),
          const SizedBox(height: 14),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.desktop_windows_outlined,
                label: '电脑 Agent 与抖音登录',
                value: '同一 Wi‑Fi',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DesktopAgentScreen(),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.cloud_outlined,
                label: '服务器托管',
                value: '暂未填写',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RuntimeSettingsScreen(),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.chat_bubble_outline_rounded,
                label: '消息模板',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TemplatesScreen(),
                  ),
                ),
              ),
              _SettingsTile(
                icon: Icons.key_rounded,
                label: '部署助手 API',
                value: _apiConfigured ? '已配置' : '选填，仅云端部署使用',
                onTap: _openApiSettings,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingsGroup(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_none_rounded),
                title: const Text('通知设置'),
                value: _notificationsEnabled,
                onChanged: (value) =>
                    setState(() => _notificationsEnabled = value),
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: '关于我们',
                value: 'sheeplhy',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
                ),
              ),
              const _SettingsTile(
                icon: Icons.help_outline_rounded,
                label: '帮助与反馈',
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFF29A9C),
                foregroundColor: const Color(0xFF5B2023),
              ),
              child: const Text('退出登录'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFDDE8ED),
              foregroundColor: Color(0xFF7792A6),
              child: Icon(Icons.person_rounded, size: 38),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '个人中心',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Text(
                    'ID: 10086',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      clipBehavior: Clip.antiAlias,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.text),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
      onTap: onTap,
    );
  }
}
