import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../ui/core/light_panel.dart';
import 'connection_test_screen.dart';

enum RuntimeChoice { computer, cloud }

class RuntimeSettingsScreen extends StatefulWidget {
  const RuntimeSettingsScreen({super.key});

  @override
  State<RuntimeSettingsScreen> createState() => _RuntimeSettingsScreenState();
}

class _RuntimeSettingsScreenState extends State<RuntimeSettingsScreen> {
  RuntimeChoice _choice = RuntimeChoice.computer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          LightPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '运行模式',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  '请选择程序运行的方式',
                  style: TextStyle(color: AppColors.inkMuted),
                ),
                const SizedBox(height: 16),
                _RuntimeOption(
                  title: '自己的电脑',
                  subtitle: '电脑启动后运行，手机负责控制',
                  icon: Icons.laptop_windows_rounded,
                  selected: _choice == RuntimeChoice.computer,
                  onTap: () => setState(() => _choice = RuntimeChoice.computer),
                ),
                const SizedBox(height: 10),
                _RuntimeOption(
                  title: '云端服务器',
                  subtitle: '电脑关机后仍可运行，适合全天候任务',
                  icon: Icons.cloud_queue_rounded,
                  selected: _choice == RuntimeChoice.cloud,
                  recommended: true,
                  onTap: () => setState(() => _choice = RuntimeChoice.cloud),
                ),
                const SizedBox(height: 20),
                Text(
                  '服务地址',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '请输入服务器地址',
                  style: TextStyle(color: AppColors.inkMuted),
                ),
                const SizedBox(height: 10),
                TextField(
                  enabled: _choice == RuntimeChoice.cloud,
                  style: TextStyle(color: AppColors.ink),
                  decoration: InputDecoration(
                    hintText: '以后部署服务器后再填写',
                    hintStyle: TextStyle(color: AppColors.inkMuted),
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _choice == RuntimeChoice.cloud
                        ? () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ConnectionTestScreen(),
                            ),
                          )
                        : null,
                    child: const Text('测试连接'),
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.circle, size: 8, color: AppColors.muted),
                    SizedBox(width: 6),
                    Text('未连接', style: TextStyle(color: AppColors.inkMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RuntimeOption extends StatelessWidget {
  const _RuntimeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.recommended = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF36B99B) : const Color(0xFFD8E4E1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF168D72) : AppColors.inkMuted,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            '推荐',
                            style: TextStyle(
                              color: AppColors.background,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? const Color(0xFF168D72) : AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}
