/// Kampüsten paylaşılan bir fotoğraf.
///
/// Kategori taşımaz — Lost & Found'un aksine burada bir sınıflandırma
/// anlamlı değil. `likedBy` uid listesi hem beğeni sayısını (`.length`) hem
/// de "ben beğendim mi" durumunu (`.contains(uid)`) tek alandan verir; ayrı
/// bir sayaç tutulmaz.
class CampusPhoto {
  final String id;
  final String authorUid;
  final String authorName;
  final String imageUrl;
  final String caption;
  final List<String> likedBy;
  final DateTime createdAt;

  CampusPhoto({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.imageUrl,
    required this.caption,
    required this.likedBy,
    required this.createdAt,
  });

  bool likedByUser(String? uid) => uid != null && likedBy.contains(uid);

  factory CampusPhoto.fromJson(Map<String, dynamic> json) => CampusPhoto(
    id: json['id'] as String? ?? '',
    authorUid: json['authorUid'] as String? ?? '',
    authorName: json['authorName'] as String? ?? '',
    imageUrl: json['imageUrl'] as String? ?? '',
    caption: json['caption'] as String? ?? '',
    likedBy: List<String>.from(json['likedBy'] ?? const []),
    createdAt: json['createdAt'] != null
        ? (json['createdAt'] as dynamic).toDate()
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorUid': authorUid,
    'authorName': authorName,
    'imageUrl': imageUrl,
    'caption': caption,
    'likedBy': likedBy,
    'createdAt': createdAt,
  };

  CampusPhoto copyWith({
    String? id,
    String? authorUid,
    String? authorName,
    String? imageUrl,
    String? caption,
    List<String>? likedBy,
    DateTime? createdAt,
  }) => CampusPhoto(
    id: id ?? this.id,
    authorUid: authorUid ?? this.authorUid,
    authorName: authorName ?? this.authorName,
    imageUrl: imageUrl ?? this.imageUrl,
    caption: caption ?? this.caption,
    likedBy: likedBy ?? this.likedBy,
    createdAt: createdAt ?? this.createdAt,
  );
}
