import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../ui/core/light_panel.dart';
import 'api_settings_store.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  final _store = ApiSettingsStore();

  ApiProvider _provider = ApiProvider.openAiCompatible;
  bool _loading = true;
  bool _saving = false;
  bool _showApiKey = false;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _store.load();
      if (!mounted) return;
      _provider = settings.provider;
      _baseUrlController.text = settings.baseUrl;
      _apiKeyController.text = settings.apiKey;
      _modelController.text = settings.model;
      _showAdvanced = settings.provider == ApiProvider.custom;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeProvider(ApiProvider? provider) {
    if (provider == null || provider == _provider) return;

    final oldProvider = _provider;
    final replaceUrl =
        _baseUrlController.text.trim().isEmpty ||
        _baseUrlController.text.trim() == oldProvider.defaultBaseUrl;
    final replaceModel =
        _modelController.text.trim().isEmpty ||
        _modelController.text.trim() == oldProvider.defaultModel;

    setState(() {
      _provider = provider;
      _showAdvanced = provider == ApiProvider.custom;
    });
    if (replaceUrl) _baseUrlController.text = provider.defaultBaseUrl;
    if (replaceModel) _modelController.text = provider.defaultModel;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      await _store.save(
        ApiSettingsData(
          provider: _provider,
          baseUrl: _baseUrlController.text,
          apiKey: _apiKeyController.text,
          model: _modelController.text,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API 设置已保存在当前设备'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearApiKey() async {
    await _store.clearApiKey();
    _apiKeyController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已清除本机保存的 API Key'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateUrl(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '请输入 API 地址';
    final uri = Uri.tryParse(text);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return '请输入完整的 http:// 或 https:// 地址';
    }
    return null;
  }

  String? _required(String? value, String message) =>
      value == null || value.trim().isEmpty ? message : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('部署助手 API')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  LightPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.key_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '云端一键部署使用你自己的 API',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: AppColors.ink,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '只用于 AI Agent 帮你配置服务器。自己的电脑模式、抖音登录和续火花消息都不会调用 API。',
                          style: TextStyle(
                            color: AppColors.inkMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<ApiProvider>(
                    initialValue: _provider,
                    decoration: const InputDecoration(
                      labelText: 'API 服务商',
                      prefixIcon: Icon(Icons.hub_outlined),
                    ),
                    items: ApiProvider.values
                        .map(
                          (provider) => DropdownMenuItem(
                            value: provider,
                            child: Text(provider.label),
                          ),
                        )
                        .toList(),
                    onChanged: _saving ? null : _changeProvider,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _apiKeyController,
                    enabled: !_saving,
                    autocorrect: false,
                    enableSuggestions: false,
                    obscureText: !_showApiKey,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: '粘贴你自己的密钥',
                      prefixIcon: const Icon(Icons.password_rounded),
                      suffixIcon: IconButton(
                        tooltip: _showApiKey ? '隐藏密钥' : '显示密钥',
                        onPressed: () =>
                            setState(() => _showApiKey = !_showApiKey),
                        icon: Icon(
                          _showApiKey
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => _required(value, '请输入 API Key'),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: ExpansionTile(
                      key: ValueKey(
                        'advanced-${_provider.name}-$_showAdvanced',
                      ),
                      initiallyExpanded: _showAdvanced,
                      onExpansionChanged: (expanded) {
                        _showAdvanced = expanded;
                      },
                      leading: const Icon(Icons.tune_rounded),
                      title: const Text('高级设置'),
                      subtitle: const Text('一般不需要修改'),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        TextFormField(
                          controller: _baseUrlController,
                          enabled: !_saving,
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'API 地址',
                            hintText: 'https://api.example.com/v1',
                            prefixIcon: Icon(Icons.link_rounded),
                          ),
                          validator: _validateUrl,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _modelController,
                          enabled: !_saving,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: '模型名称',
                            hintText: '填写服务商提供的模型 ID',
                            prefixIcon: Icon(Icons.smart_toy_outlined),
                          ),
                          validator: (value) => _required(value, '请输入模型名称'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '设置仅保存在当前设备，不会上传给火花管家开发者。浏览器会使用本地存储，请勿在公共设备保存密钥。',
                    style: TextStyle(color: AppColors.muted, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? '保存中…' : '保存设置'),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _clearApiKey,
                    child: const Text('清除本机 API Key'),
                  ),
                ],
              ),
            ),
    );
  }
}
