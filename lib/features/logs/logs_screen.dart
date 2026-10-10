import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../ui/core/empty_state_panel.dart';
import '../../ui/core/page_header.dart';
import '../connection/desktop_agent_client.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});
  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  Map<String, dynamic>? _status;
  Map<String, dynamic>? _result;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = await DesktopAgentClient.fromSavedSettings();
      if (client == null) throw const AgentException('尚未连接电脑 Agent');
      final status = await client.status();
      final resultEnvelope = await client.result();
      if (!mounted) return;
      setState(() {
        _status = status;
        _result = resultEnvelope['result'] as Map<String, dynamic>?;
      });
    } on AgentException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = (_result?['results'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            PageHeader(
              title: '执行记录',
              subtitle: '只显示脱敏后的结果，不含消息全文',
              trailing: IconButton.filled(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading) const LinearProgressIndicator(),
            Card(
              child: ListTile(
                leading: Icon(
                  _status?['running'] == true
                      ? Icons.sync_rounded
                      : Icons.computer_rounded,
                  color: AppColors.primary,
                ),
                title: Text(_status?['running'] == true ? '电脑正在执行' : '电脑当前空闲'),
                subtitle: Text(
                  _status == null
                      ? (_error ?? '等待连接')
                      : '登录：${_status?['loggedIn'] == true ? '有效' : '需要登录'} · 自动计划：${_status?['scheduleCount'] ?? 0}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null && _status == null)
              EmptyStatePanel(
                icon: Icons.link_off_rounded,
                title: '暂时无法读取记录',
                description: _error!,
                actionLabel: '重试',
                onAction: _refresh,
              )
            else if (rows.isEmpty)
              const EmptyStatePanel(
                icon: Icons.find_in_page_outlined,
                title: '暂无执行记录',
                description: '检查或执行计划后，脱敏结果会显示在这里',
              )
            else ...[
              Text(
                '最近一次 · ${_result?['finished_at'] ?? ''}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              for (final row in rows)
                Card(
                  child: ListTile(
                    leading: Icon(
                      row['status'] == 'success'
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: row['status'] == 'success'
                          ? AppColors.primary
                          : Colors.redAccent,
                    ),
                    title: Text(row['target']?.toString() ?? '好友'),
                    subtitle: Text(
                      row['status'] == 'success'
                          ? '完成 · 发送 ${row['sent'] ?? 0} 条'
                          : '失败 · ${row['error'] ?? '请查看电脑'}',
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
