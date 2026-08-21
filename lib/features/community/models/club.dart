class Club {
  final String id;
  final String name;
  final String logoUrl;
  final String coverUrl;
  final String category;
  final String description;
  final bool verified;
  final int followerCount;
  final String adminUid;
  final List<String> adminUids;
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
    this.verified = false,
    this.adminUids = const [],
  });

  /// [uid] başkan (`adminUid`) ya da yönetici üye (`adminUids`) ise `true`.
  bool isAdmin(String uid) => uid == adminUid || adminUids.contains(uid);

  factory Club.fromJson(Map<String, dynamic> json) => Club(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    logoUrl: json['logoUrl'] as String? ?? '',
    coverUrl: json['coverUrl'] as String? ?? '',
    category: json['category'] as String? ?? '',
    description: json['description'] as String? ?? '',
    verified: json['verified'] as bool? ?? false,
    followerCount: json['followerCount'] as int? ?? 0,
    adminUid: json['adminUid'] as String? ?? '',
    adminUids: (json['adminUids'] as List?)?.cast<String>() ?? const [],
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
    'verified': verified,
    'followerCount': followerCount,
    'adminUid': adminUid,
    'adminUids': adminUids,
    'createdAt': createdAt,
  };

  Club copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? coverUrl,
    String? category,
    String? description,
    bool? verified,
    int? followerCount,
    String? adminUid,
    List<String>? adminUids,
    DateTime? createdAt,
  }) => Club(
    id: id ?? this.id,
    name: name ?? this.name,
    logoUrl: logoUrl ?? this.logoUrl,
    coverUrl: coverUrl ?? this.coverUrl,
    category: category ?? this.category,
    description: description ?? this.description,
    verified: verified ?? this.verified,
    followerCount: followerCount ?? this.followerCount,
    adminUid: adminUid ?? this.adminUid,
    adminUids: adminUids ?? this.adminUids,
    createdAt: createdAt ?? this.createdAt,
  );
}
