class BoardItem {
  final String id;
  final String title;
  final String content;
  final String authorUid;
  final String category;
  final DateTime createdAt;

  BoardItem({
    required this.id,
    required this.title,
    required this.content,
    required this.authorUid,
    required this.category,
    required this.createdAt,
  });

  factory BoardItem.fromJson(Map<String, dynamic> json) => BoardItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        authorUid: json['authorUid'] as String? ?? '',
        category: json['category'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? (json['createdAt'] as dynamic).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'authorUid': authorUid,
        'category': category,
        'createdAt': createdAt,
      };

  BoardItem copyWith({
    String? id,
    String? title,
    String? content,
    String? authorUid,
    String? category,
    DateTime? createdAt,
  }) =>
      BoardItem(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        authorUid: authorUid ?? this.authorUid,
        category: category ?? this.category,
        createdAt: createdAt ?? this.createdAt,
      );
}
