import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../ui/core/empty_state_panel.dart';
import '../../ui/core/light_panel.dart';
import '../../ui/core/page_header.dart';
import '../connection/qr_scanner_screen.dart';
import '../connection/desktop_agent_screen.dart';
import '../settings/api_settings_screen.dart';
import '../settings/api_settings_store.dart';

enum ConnectionMode { computer, server }

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _serverFormKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _userController = TextEditingController(text: 'root');

  ConnectionMode _mode = ConnectionMode.computer;
  String _authentication = 'SSH 密钥';
  bool _paired = false;

  @override
  void dispose() {
    _addressController.dispose();
    _portController.dispose();
    _userController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          PageHeader(
            title: '火花管家',
            subtitle: '简单连接，安心管理',
            showLogo: true,
            trailing: IconButton(
              tooltip: '通知',
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(height: 18),
          _RuntimeCard(mode: _mode, onTap: _chooseMode),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _mode == ConnectionMode.computer
                ? _LocalConnectionPanel(
                    key: const ValueKey('computer'),
                    paired: _paired,
                    onScan: _scanQrCode,
                    onPairCode: _enterPairingCode,
                    onDiscover: _discoverComputer,
                  )
                : _ServerConnectionPanel(
                    key: const ValueKey('server'),
                    formKey: _serverFormKey,
                    addressController: _addressController,
                    portController: _portController,
                    userController: _userController,
                    authentication: _authentication,
                    onAuthenticationChanged: (value) {
                      if (value != null) {
                        setState(() => _authentication = value);
                      }
                    },
                    onDeploy: _prepareDeployment,
                    onManualDeploy: _showManualDeployment,
                    onConnect: _openCloudAgent,
                  ),
          ),
          const SizedBox(height: 12),
          const _StatsRow(),
          const SizedBox(height: 12),
          EmptyStatePanel(
            icon: Icons.calendar_month_outlined,
            title: '暂无定时任务',
            description: '设置定时计划后，系统会按时执行任务',
            actionLabel: '去设置',
            onAction: () => _showTip('请点击底部“计划”进入计划页'),
          ),
          const SizedBox(height: 12),
          const _ShortcutRow(),
        ],
      ),
    );
  }

  Future<void> _chooseMode() async {
    final selected = await showModalBottomSheet<ConnectionMode>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '选择连接方式',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                _ModeChoiceTile(
                  icon: Icons.desktop_windows_rounded,
                  title: '本地电脑',
                  subtitle: '适合同一网络，扫码即可连接',
                  selected: _mode == ConnectionMode.computer,
                  onTap: () => Navigator.pop(context, ConnectionMode.computer),
                ),
                const SizedBox(height: 10),
                _ModeChoiceTile(
                  icon: Icons.cloud_outlined,
                  title: '云端服务器',
                  subtitle: '全天在线，可从 App 发起部署',
                  selected: _mode == ConnectionMode.server,
                  onTap: () => Navigator.pop(context, ConnectionMode.server),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) setState(() => _mode = selected);
  }

  Future<void> _scanQrCode() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const QrScannerScreen()),
    );
    if (result == null || !mounted) return;
    setState(() => _paired = true);
    _showTip('二维码已识别，正在安全配对');
  }

  Future<void> _enterPairingCode() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入电脑配对码'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: '6 位配对码',
            hintText: '例如 SPARK8',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('连接'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.isEmpty || !mounted) return;
    setState(() => _paired = true);
    _showTip('配对码已提交，正在连接电脑');
  }

  Future<void> _discoverComputer() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const DesktopAgentScreen()));
    if (mounted) setState(() => _paired = true);
  }

  Future<void> _prepareDeployment() async {
    if (!(_serverFormKey.currentState?.validate() ?? false)) return;

    var apiConfigured = false;
    try {
      apiConfigured = await ApiSettingsStore().hasCompleteSettings();
    } catch (_) {
      apiConfigured = false;
    }
    if (!mounted) return;

    if (!apiConfigured) {
      final openSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('先配置自己的 API'),
          content: const Text(
            'AI Agent 一键部署需要使用你自己的 API。选择服务商并填写 API Key 后即可继续；自己部署不需要 API。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('去配置 API'),
            ),
          ],
        ),
      );
      if (openSettings == true && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ApiSettingsScreen()),
        );
      }
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Agent 一键部署确认',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  '服务器：${_addressController.text.trim()}:${_portController.text.trim()}',
                ),
                Text('用户：${_userController.text.trim()} · $_authentication'),
                const SizedBox(height: 16),
                const Text(
                  'API Agent 将依次核对主机指纹、检查系统与 Docker、安装火花管家 Agent，并配置安全访问令牌。',
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showTip('AI Agent 部署流程已准备；接入 SSH 执行服务后即可开始');
                    },
                    child: const Text('确认 AI 一键部署'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showManualDeployment() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '自己部署',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                '在服务器中自行安装 Docker 和火花管家 Agent，完成后回到 App 填写服务地址并连接。',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 8),
              const Text(
                '自己部署不使用 AI Agent，也不需要填写 API Key。',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('知道了'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCloudAgent() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const DesktopAgentScreen(cloud: true),
      ),
    );
  }

  void _showTip(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _RuntimeCard extends StatelessWidget {
  const _RuntimeCard({required this.mode, required this.onTap});

  final ConnectionMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isComputer = mode == ConnectionMode.computer;
    return Material(
      color: AppColors.lightSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isComputer
                      ? Icons.desktop_windows_rounded
                      : Icons.cloud_outlined,
                  color: const Color(0xFF168D72),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '点击切换连接模式',
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isComputer ? '本地电脑' : '云端服务器',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      isComputer ? '扫码、配对码或局域网发现' : '填写地址后准备一键部署',
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.unfold_more_rounded, color: AppColors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalConnectionPanel extends StatelessWidget {
  const _LocalConnectionPanel({
    required this.paired,
    required this.onScan,
    required this.onPairCode,
    required this.onDiscover,
    super.key,
  });

  final bool paired;
  final VoidCallback onScan;
  final VoidCallback onPairCode;
  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link_rounded, color: Color(0xFF168D72)),
              const SizedBox(width: 8),
              Text(
                paired ? '电脑已配对' : '连接自己的电脑',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            paired ? '连接信息已保存，可随时检查在线状态。' : '先在电脑端打开火花管家，然后选择一种连接方式。',
            style: const TextStyle(color: AppColors.inkMuted, height: 1.45),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('扫码连接'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPairCode,
                  icon: const Icon(Icons.pin_outlined),
                  label: const Text('输入配对码'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: onDiscover,
              icon: const Icon(Icons.wifi_find_rounded),
              label: const Text('连接电脑 Agent / 抖音登录'),
            ),
          ),
          const Text(
            '配对二维码和配对码应短时有效、单次使用，不包含账号密码。',
            style: TextStyle(
              color: AppColors.inkMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerConnectionPanel extends StatelessWidget {
  const _ServerConnectionPanel({
    required this.formKey,
    required this.addressController,
    required this.portController,
    required this.userController,
    required this.authentication,
    required this.onAuthenticationChanged,
    required this.onDeploy,
    required this.onManualDeploy,
    required this.onConnect,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController addressController;
  final TextEditingController portController;
  final TextEditingController userController;
  final String authentication;
  final ValueChanged<String?> onAuthenticationChanged;
  final VoidCallback onDeploy;
  final VoidCallback onManualDeploy;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return LightPanel(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '连接云端服务器',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              '填写 SSH 信息，确认主机指纹后再部署。',
              style: TextStyle(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: addressController,
              style: const TextStyle(color: AppColors.ink),
              decoration: const InputDecoration(
                labelText: '服务器地址',
                hintText: 'IP 地址或域名',
                prefixIcon: Icon(Icons.dns_outlined),
                fillColor: Colors.white,
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '请输入服务器地址' : null,
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: portController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.ink),
                    decoration: const InputDecoration(
                      labelText: 'SSH 端口',
                      fillColor: Colors.white,
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? '必填' : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: userController,
                    style: const TextStyle(color: AppColors.ink),
                    decoration: const InputDecoration(
                      labelText: 'SSH 用户',
                      fillColor: Colors.white,
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? '必填' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: authentication,
              dropdownColor: Colors.white,
              style: const TextStyle(color: AppColors.ink),
              decoration: const InputDecoration(
                labelText: '认证方式',
                prefixIcon: Icon(Icons.key_outlined),
                fillColor: Colors.white,
              ),
              items: const [
                DropdownMenuItem(value: 'SSH 密钥', child: Text('SSH 密钥（推荐）')),
                DropdownMenuItem(value: '临时密码', child: Text('临时密码')),
              ],
              onChanged: onAuthenticationChanged,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onDeploy,
                icon: const Icon(Icons.rocket_launch_outlined),
                label: const Text('AI Agent 一键部署'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onManualDeploy,
                icon: const Icon(Icons.terminal_rounded),
                label: const Text('自己部署'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onConnect,
                icon: const Icon(Icons.link_rounded),
                label: const Text('服务器已部署，填写 Agent 地址'),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI Agent 一键部署需要先配置自己的 API；自己部署不需要 API。',
              style: TextStyle(
                color: AppColors.inkMuted,
                fontSize: 10.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '服务器要求：建议 Ubuntu 22.04/24.04 或 Debian 12、x86_64、至少 2 核 2 GB、可通过 SSH 访问。部署方式：核验主机指纹后安装 Docker 与火花管家 Agent；推荐使用 SSH 密钥和 HTTPS/私有网络。',
              style: TextStyle(
                color: AppColors.inkMuted,
                fontSize: 10.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChoiceTile extends StatelessWidget {
  const _ModeChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.outline,
        ),
      ),
      tileColor: selected
          ? AppColors.primary.withValues(alpha: 0.1)
          : AppColors.surface,
      leading: Icon(
        icon,
        color: selected ? AppColors.primary : AppColors.muted,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        selected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? AppColors.primary : AppColors.muted,
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    const stats = [
      ('好友（不限）', '0', AppColors.primary),
      ('待执行任务', '0', AppColors.ink),
      ('今日已发送', '0', AppColors.ink),
    ];

    return LightPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Row(
        children: [
          for (var index = 0; index < stats.length; index++) ...[
            Expanded(
              child: Column(
                children: [
                  Text(
                    stats[index].$1,
                    style: const TextStyle(
                      color: AppColors.inkMuted,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    stats[index].$2,
                    style: TextStyle(
                      color: stats[index].$3,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (index != stats.length - 1)
              const SizedBox(
                height: 38,
                child: VerticalDivider(color: Color(0xFFD8E4E1)),
              ),
          ],
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ShortcutCard(
            icon: Icons.schedule_rounded,
            color: AppColors.primary,
            title: '定时计划',
            subtitle: '规划你的互动时间',
            onTap: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ShortcutCard(
            icon: Icons.description_rounded,
            color: const Color(0xFF5C95F5),
            title: '执行记录',
            subtitle: '查看任务执行情况',
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.lightSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.inkMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
