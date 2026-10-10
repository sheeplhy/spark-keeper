import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static final Uri _projectUri = Uri.parse(
    'https://github.com/sheeplhy/sheeplhy.github.io',
  );

  Future<void> _openProject(BuildContext context) async {
    final opened = await launchUrl(
      _projectUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('无法打开浏览器，可长按或复制项目地址')));
    }
  }

  Future<void> _copyProjectUrl(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _projectUri.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('项目地址已复制')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于我们')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: AppColors.surfaceHigh,
              foregroundColor: AppColors.primary,
              child: Icon(Icons.local_fire_department_rounded, size: 48),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '火花管家',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            '让每一次互动都有温度',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '开发者',
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'sheeplhy',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '项目主页',
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    _projectUri.toString(),
                    style: const TextStyle(color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _openProject(context),
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('打开项目主页'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton.outlined(
                        tooltip: '复制地址',
                        onPressed: () => _copyProjectUrl(context),
                        icon: const Icon(Icons.copy_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '本工具仅供个人学习和非商业用途。请遵守平台规则，只操作自己的账号，并妥善保管登录凭据。',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.6),
          ),
          const SizedBox(height: 12),
          const Text(
            '版本 0.1.0',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
