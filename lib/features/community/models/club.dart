class Club {
  final String id;
  final String name;
  final String logoUrl;
  final String category;
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
  });

  factory Club.fromJson(Map<String, dynamic> json) => Club(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    logoUrl: json['logoUrl'] as String? ?? '',
    category: json['category'] as String? ?? '',
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
    'category': category,
    'followerCount': followerCount,
    'adminUid': adminUid,
    'createdAt': createdAt,
  };

  Club copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? category,
    int? followerCount,
    String? adminUid,
    DateTime? createdAt,
  }) => Club(
    id: id ?? this.id,
    name: name ?? this.name,
    logoUrl: logoUrl ?? this.logoUrl,
    category: category ?? this.category,
    followerCount: followerCount ?? this.followerCount,
    adminUid: adminUid ?? this.adminUid,
    createdAt: createdAt ?? this.createdAt,
  );
}
