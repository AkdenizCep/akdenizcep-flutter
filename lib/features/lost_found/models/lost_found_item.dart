/// Kayıp ya da bulundu ilanı. `type` alanı `'kayip'` ya da `'bulundu'` olur.
class LostFoundItem {
  final String id;
  final String authorUid;
  final String authorName;
  final String type;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final String location;
  final String contactPhone;
  final bool isResolved;
  final DateTime createdAt;

  LostFoundItem({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.location,
    required this.contactPhone,
    required this.isResolved,
    required this.createdAt,
  });

  bool get isLost => type == 'kayip';

  factory LostFoundItem.fromJson(Map<String, dynamic> json) => LostFoundItem(
    id: json['id'] as String? ?? '',
    authorUid: json['authorUid'] as String? ?? '',
    authorName: json['authorName'] as String? ?? '',
    type: json['type'] as String? ?? 'kayip',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    category: json['category'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    location: json['location'] as String? ?? '',
    contactPhone: json['contactPhone'] as String? ?? '',
    isResolved: json['isResolved'] as bool? ?? false,
    createdAt: json['createdAt'] != null
        ? (json['createdAt'] as dynamic).toDate()
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorUid': authorUid,
    'authorName': authorName,
    'type': type,
    'title': title,
    'description': description,
    'category': category,
    'imageUrl': imageUrl,
    'location': location,
    'contactPhone': contactPhone,
    'isResolved': isResolved,
    'createdAt': createdAt,
  };

  LostFoundItem copyWith({
    String? id,
    String? authorUid,
    String? authorName,
    String? type,
    String? title,
    String? description,
    String? category,
    String? imageUrl,
    String? location,
    String? contactPhone,
    bool? isResolved,
    DateTime? createdAt,
  }) => LostFoundItem(
    id: id ?? this.id,
    authorUid: authorUid ?? this.authorUid,
    authorName: authorName ?? this.authorName,
    type: type ?? this.type,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    imageUrl: imageUrl ?? this.imageUrl,
    location: location ?? this.location,
    contactPhone: contactPhone ?? this.contactPhone,
    isResolved: isResolved ?? this.isResolved,
    createdAt: createdAt ?? this.createdAt,
  );
}
