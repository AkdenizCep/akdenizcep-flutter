class Club {
  final String id;
  final String name;
  final String logoUrl;
  final String coverUrl;
  final String category;
  final String description;
  final int? foundedYear;
  final bool verified;
  final int followerCount;
  final String adminUid;
  final DateTime createdAt;

  Club({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.category,
    required this.followerCount,
    required this.adminUid,
    required this.createdAt,
    this.coverUrl = '',
    this.description = '',
    this.foundedYear,
    this.verified = false,
  });

  factory Club.fromJson(Map<String, dynamic> json) => Club(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    logoUrl: json['logoUrl'] as String? ?? '',
    coverUrl: json['coverUrl'] as String? ?? '',
    category: json['category'] as String? ?? '',
    description: json['description'] as String? ?? '',
    foundedYear: json['foundedYear'] as int?,
    verified: json['verified'] as bool? ?? false,
    followerCount: json['followerCount'] as int? ?? 0,
    adminUid: json['adminUid'] as String? ?? '',
    createdAt: json['createdAt'] != null
        ? (json['createdAt'] as dynamic).toDate()
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logoUrl': logoUrl,
    'coverUrl': coverUrl,
    'category': category,
    'description': description,
    'foundedYear': foundedYear,
    'verified': verified,
    'followerCount': followerCount,
    'adminUid': adminUid,
    'createdAt': createdAt,
  };

  Club copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? coverUrl,
    String? category,
    String? description,
    int? foundedYear,
    bool? verified,
    int? followerCount,
    String? adminUid,
    DateTime? createdAt,
  }) => Club(
    id: id ?? this.id,
    name: name ?? this.name,
    logoUrl: logoUrl ?? this.logoUrl,
    coverUrl: coverUrl ?? this.coverUrl,
    category: category ?? this.category,
    description: description ?? this.description,
    foundedYear: foundedYear ?? this.foundedYear,
    verified: verified ?? this.verified,
    followerCount: followerCount ?? this.followerCount,
    adminUid: adminUid ?? this.adminUid,
    createdAt: createdAt ?? this.createdAt,
  );
}
