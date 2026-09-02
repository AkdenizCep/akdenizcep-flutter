class UserProfileSummary {
  final String uid;
  final String name;
  final String photoUrl;

  const UserProfileSummary({
    required this.uid,
    required this.name,
    this.photoUrl = '',
  });

  factory UserProfileSummary.fromJson(Map<String, dynamic> json, [String? id]) {
    return UserProfileSummary(
      uid: id ?? json['id'] as String? ?? json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'photoUrl': photoUrl,
  };

  UserProfileSummary copyWith({
    String? uid,
    String? name,
    String? photoUrl,
  }) {
    return UserProfileSummary(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileSummary &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          name == other.name &&
          photoUrl == other.photoUrl;

  @override
  int get hashCode => Object.hash(uid, name, photoUrl);
}
