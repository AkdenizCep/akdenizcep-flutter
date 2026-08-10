/// Etkinlik altındaki soru/yorum.
class EventComment {
  final String id;
  final String authorUid;
  final String authorName;
  final String text;
  final DateTime createdAt;

  const EventComment({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  factory EventComment.fromJson(Map<String, dynamic> json) => EventComment(
    id: json['id'] as String? ?? '',
    authorUid: json['authorUid'] as String? ?? '',
    authorName: json['authorName'] as String? ?? '',
    text: json['text'] as String? ?? '',
    createdAt: json['createdAt'] != null
        ? (json['createdAt'] as dynamic).toDate()
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorUid': authorUid,
    'authorName': authorName,
    'text': text,
    'createdAt': createdAt,
  };

  EventComment copyWith({
    String? id,
    String? authorUid,
    String? authorName,
    String? text,
    DateTime? createdAt,
  }) => EventComment(
    id: id ?? this.id,
    authorUid: authorUid ?? this.authorUid,
    authorName: authorName ?? this.authorName,
    text: text ?? this.text,
    createdAt: createdAt ?? this.createdAt,
  );
}
