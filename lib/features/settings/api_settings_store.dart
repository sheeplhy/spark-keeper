import 'package:shared_preferences/shared_preferences.dart';

enum ApiProvider {
  openAiCompatible,
  deepSeek,
  qwen,
  custom;

  String get label => switch (this) {
    ApiProvider.openAiCompatible => 'OpenAI 兼容 API',
    ApiProvider.deepSeek => 'DeepSeek',
    ApiProvider.qwen => '通义千问',
    ApiProvider.custom => '自定义服务',
  };

  String get defaultBaseUrl => switch (this) {
    ApiProvider.openAiCompatible => 'https://api.openai.com/v1',
    ApiProvider.deepSeek => 'https://api.deepseek.com',
    ApiProvider.qwen => 'https://dashscope.aliyuncs.com/compatible-mode/v1',
    ApiProvider.custom => '',
  };

  String get defaultModel => switch (this) {
    ApiProvider.openAiCompatible => 'gpt-5-mini',
    ApiProvider.deepSeek => 'deepseek-flash',
    ApiProvider.qwen => 'qwen-plus',
    ApiProvider.custom => '',
  };
}

class ApiSettingsData {
  const ApiSettingsData({
    required this.provider,
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  final ApiProvider provider;
  final String baseUrl;
  final String apiKey;
  final String model;

  bool get isConfigured =>
      baseUrl.trim().isNotEmpty &&
      apiKey.trim().isNotEmpty &&
      model.trim().isNotEmpty;
}

class ApiSettingsStore {
  ApiSettingsStore({this._preferences});

  static const _providerKey = 'api.provider';
  static const _baseUrlKey = 'api.baseUrl';
  static const _apiKeyKey = 'api.key';
  static const _modelKey = 'api.model';

  final SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async =>
      _preferences ?? SharedPreferences.getInstance();

  Future<ApiSettingsData> load() async {
    final preferences = await _prefs;
    final providerName = preferences.getString(_providerKey);
    final provider = ApiProvider.values.firstWhere(
      (value) => value.name == providerName,
      orElse: () => ApiProvider.openAiCompatible,
    );

    return ApiSettingsData(
      provider: provider,
      baseUrl: preferences.getString(_baseUrlKey) ?? provider.defaultBaseUrl,
      apiKey: preferences.getString(_apiKeyKey) ?? '',
      model: preferences.getString(_modelKey) ?? provider.defaultModel,
    );
  }

  Future<void> save(ApiSettingsData settings) async {
    final preferences = await _prefs;
    await Future.wait<bool>([
      preferences.setString(_providerKey, settings.provider.name),
      preferences.setString(_baseUrlKey, settings.baseUrl.trim()),
      preferences.setString(_apiKeyKey, settings.apiKey.trim()),
      preferences.setString(_modelKey, settings.model.trim()),
    ]);
  }

  Future<void> clearApiKey() async {
    await (await _prefs).remove(_apiKeyKey);
  }

  Future<bool> hasCompleteSettings() async => (await load()).isConfigured;
}
