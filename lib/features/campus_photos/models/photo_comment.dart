/// Bir kampüs fotoğrafı altındaki yorum.
class PhotoComment {
  final String id;
  final String authorUid;
  final String authorName;
  final String text;
  final DateTime createdAt;

  const PhotoComment({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  factory PhotoComment.fromJson(Map<String, dynamic> json) => PhotoComment(
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
}
