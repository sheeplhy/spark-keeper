import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../ui/core/empty_state_panel.dart';
import '../../ui/core/page_header.dart';
import 'message_template.dart';
import 'template_store.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({super.key});
  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final _store = TemplateStore();
  final _search = TextEditingController();
  List<MessageTemplate> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _store.load();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _save(List<MessageTemplate> items) async {
    setState(() => _items = items);
    await _store.save(items);
  }

  Future<void> _edit([MessageTemplate? existing]) async {
    final result = await Navigator.of(context).push<MessageTemplate>(
      MaterialPageRoute(builder: (_) => _TemplateEditor(existing: existing)),
    );
    if (result == null) return;
    if (existing == null) {
      await _save([..._items, result]);
    } else {
      await _save([
        for (final item in _items)
          if (item.id == existing.id) result else item,
      ]);
    }
  }

  Future<void> _delete(MessageTemplate item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除模板？'),
        content: Text('“${item.title}”删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _save(_items.where((other) => other.id != item.id).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final visible =
        _items
            .where(
              (item) =>
                  query.isEmpty ||
                  item.title.toLowerCase().contains(query) ||
                  item.content.toLowerCase().contains(query),
            )
            .toList()
          ..sort((a, b) => (b.favorite ? 1 : 0).compareTo(a.favorite ? 1 : 0));
    return Scaffold(
      appBar: AppBar(title: const Text('消息模板')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            PageHeader(
              title: '常用消息',
              subtitle: '支持文字、换行和 Emoji',
              trailing: IconButton.filled(
                tooltip: '新建模板',
                onPressed: _edit,
                icon: const Icon(Icons.add_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: '搜索模板',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (visible.isEmpty)
              EmptyStatePanel(
                icon: Icons.chat_bubble_outline_rounded,
                title: query.isEmpty ? '还没有消息模板' : '没有匹配模板',
                description: '创建一条常用内容，计划中也可直接输入',
                actionLabel: query.isEmpty ? '新建模板' : null,
                onAction: query.isEmpty ? _edit : null,
              )
            else
              for (final item in visible) ...[
                Card(
                  child: InkWell(
                    onTap: () => _edit(item),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.content,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  item.category,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: item.favorite ? '取消收藏' : '收藏',
                            onPressed: () => _save([
                              for (final other in _items)
                                if (other.id == item.id)
                                  other.copyWith(favorite: !other.favorite)
                                else
                                  other,
                            ]),
                            icon: Icon(
                              item.favorite
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                            ),
                          ),
                          IconButton(
                            tooltip: '删除',
                            onPressed: () => _delete(item),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _edit,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _TemplateEditor extends StatefulWidget {
  const _TemplateEditor({this.existing});
  final MessageTemplate? existing;
  @override
  State<_TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends State<_TemplateEditor> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  late final TextEditingController _category;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _content = TextEditingController(text: widget.existing?.content ?? '');
    _category = TextEditingController(text: widget.existing?.category ?? '常用');
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _category.dispose();
    super.dispose();
  }

  void _insertEmoji(String emoji) {
    final selection = _content.selection;
    final position = selection.isValid ? selection.start : _content.text.length;
    _content.text = _content.text.replaceRange(position, position, emoji);
    _content.selection = TextSelection.collapsed(
      offset: position + emoji.length,
    );
  }

  void _save() {
    if (_title.text.trim().isEmpty || _content.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入名称和消息内容')));
      return;
    }
    Navigator.pop(
      context,
      MessageTemplate(
        id:
            widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        content: _content.text.trim(),
        category: _category.text.trim().isEmpty ? '常用' : _category.text.trim(),
        favorite: widget.existing?.favorite ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const emojis = ['🔥', '😊', '❤️', '👍', '✨', '哈哈', '晚安'];
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? '新建模板' : '编辑模板')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: '模板名称'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _category,
            decoration: const InputDecoration(labelText: '分类'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _content,
            minLines: 5,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: '消息内容',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final emoji in emojis)
                ActionChip(
                  label: Text(emoji),
                  onPressed: () => _insertEmoji(emoji),
                ),
            ],
          ),
          const SizedBox(height: 22),
          FilledButton(onPressed: _save, child: const Text('保存模板')),
        ],
      ),
    );
  }
}
