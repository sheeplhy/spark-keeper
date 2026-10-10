class MessageTemplate {
  const MessageTemplate({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.favorite = false,
  });
  final String id;
  final String title;
  final String content;
  final String category;
  final bool favorite;

  MessageTemplate copyWith({
    String? title,
    String? content,
    String? category,
    bool? favorite,
  }) => MessageTemplate(
    id: id,
    title: title ?? this.title,
    content: content ?? this.content,
    category: category ?? this.category,
    favorite: favorite ?? this.favorite,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'category': category,
    'favorite': favorite,
  };
  factory MessageTemplate.fromJson(Map<String, dynamic> json) =>
      MessageTemplate(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        category: json['category'] as String? ?? '常用',
        favorite: json['favorite'] as bool? ?? false,
      );
}
