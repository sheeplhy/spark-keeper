import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import 'desktop_agent_client.dart';
import 'desktop_agent_settings.dart';

class DesktopAgentScreen extends StatefulWidget {
  const DesktopAgentScreen({super.key, this.cloud = false});
  final bool cloud;
  @override
  State<DesktopAgentScreen> createState() => _DesktopAgentScreenState();
}

class _DesktopAgentScreenState extends State<DesktopAgentScreen> {
  late final TextEditingController _address;
  final _token = TextEditingController();
  final _store = DesktopAgentSettingsStore();
  DesktopAgentClient? _client;
  Timer? _timer;
  Uint8List? _qr;
  String _status = '未连接';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _address = TextEditingController(
      text: widget.cloud ? '' : 'http://192.168.1.2:8765',
    );
    _restore();
  }

  Future<void> _restore() async {
    final settings = await _store.load();
    if (settings == null || !mounted) return;
    _address.text = settings.baseUrl;
    _token.text = settings.token;
    _client = DesktopAgentClient(settings);
    await _refreshStatus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _address.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_address.text.trim().isEmpty || _token.text.trim().isEmpty) {
      _show('请填写电脑地址和控制台显示的配对令牌');
      return;
    }
    setState(() => _busy = true);
    final settings = DesktopAgentSettings(
      baseUrl: _address.text.trim(),
      token: _token.text.trim(),
    );
    final client = DesktopAgentClient(settings);
    try {
      await client.health();
      await client.status();
      await _store.save(settings);
      _client = client;
      if (mounted) setState(() => _status = '电脑已连接');
    } on AgentException catch (error) {
      _show(error.message);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _startLogin() async {
    final client = _client;
    if (client == null) {
      _show('请先连接电脑');
      return;
    }
    try {
      await client.startLogin();
      if (mounted) {
        setState(() {
          _status = '等待扫码';
          _qr = null;
        });
      }
      _timer?.cancel();
      _timer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _refreshLogin(),
      );
      await _refreshLogin();
    } on AgentException catch (error) {
      _show(error.message);
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await _client?.status();
      if (status != null && mounted) {
        setState(
          () => _status = status['loggedIn'] == true ? '电脑已登录抖音' : '电脑已连接，尚未登录',
        );
      }
    } on AgentException catch (error) {
      if (mounted) setState(() => _status = error.message);
    }
  }

  Future<void> _refreshLogin() async {
    final client = _client;
    if (client == null) return;
    try {
      final status = await client.loginStatus();
      final qr = await client.loginQr();
      if (!mounted) return;
      final state = status['state'] as String? ?? 'starting';
      setState(() {
        _status = _label(state);
        if (qr != null) _qr = qr;
      });
      if (state == 'logged_in' || state == 'error') _timer?.cancel();
    } on AgentException catch (error) {
      if (mounted) setState(() => _status = error.message);
    }
  }

  String _label(String state) => switch (state) {
    'waiting_qr' => '请用抖音 App 扫码并确认',
    'waiting_confirmation' => '已扫码，请在抖音 App 确认',
    'verification_required' => '需要人工验证，请在电脑浏览器完成',
    'logged_in' => '登录成功，凭据仅保存在电脑',
    'error' => '登录失败，请重新开始',
    _ => '正在打开抖音登录页',
  };

  void _show(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.cloud ? '连接服务器 Agent' : '连接自己的电脑')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.cloud ? '服务器部署完成后，在这里填写 HTTPS 地址和部署时设置的令牌。服务器未准备好可先留空。' : '电脑与手机连接同一个 Wi‑Fi，在电脑启动 desktop_agent/bridge.py。控制台会显示局域网地址和配对令牌。',
            style: TextStyle(color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _address,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: '电脑地址',
              hintText: widget.cloud
                  ? 'https://你的域名'
                  : 'http://192.168.1.2:8765',
              prefixIcon: const Icon(Icons.computer_rounded),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _token,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '配对令牌',
              prefixIcon: Icon(Icons.key_rounded),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _busy ? null : _connect,
            icon: const Icon(Icons.link_rounded),
            label: Text(_busy ? '连接中…' : '保存并测试连接'),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 11,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _status,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  if (_qr != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.white,
                      child: Image.memory(
                        _qr!,
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '这是电脑浏览器中的同一张二维码，也可直接看电脑浏览器扫码。',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _client == null ? null : _startLogin,
                      icon: const Icon(Icons.qr_code_2_rounded),
                      label: const Text('打开抖音扫码登录'),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _client == null ? null : _refreshLogin,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('刷新二维码与状态'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.cloud
                ? '安全说明：服务器端口默认只绑定 127.0.0.1，请通过 HTTPS 反向代理或私有 VPN 访问。不要直接暴露无 TLS 的 8765 端口。'
                : '安全说明：App 只接收二维码图片和状态；Cookie、验证码、账号密码不会传到手机。不要把 8765 端口映射到公网。异地使用建议安全组网/VPN。',
            style: TextStyle(
              color: AppColors.muted,
              height: 1.45,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
