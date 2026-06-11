class Announcement {
  final String id;
  final String imageUrl;
  final String title;
  final String context;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.context,
    required this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? '',
        title: json['title'] as String? ?? '',
        context: json['context'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? (json['createdAt'] as dynamic).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageUrl': imageUrl,
        'title': title,
        'context': context,
        'createdAt': createdAt,
      };

  Announcement copyWith({
    String? id,
    String? imageUrl,
    String? title,
    String? context,
    DateTime? createdAt,
  }) =>
      Announcement(
        id: id ?? this.id,
        imageUrl: imageUrl ?? this.imageUrl,
        title: title ?? this.title,
        context: context ?? this.context,
        createdAt: createdAt ?? this.createdAt,
      );
}
