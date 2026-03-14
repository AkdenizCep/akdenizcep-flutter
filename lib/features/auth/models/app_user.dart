class AppUser {
  final String id;
  final String name;
  final String email;
  final String studentId;
  final List<String> followedClubs;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.followedClubs,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        studentId: json['studentId'] as String? ?? '',
        followedClubs: List<String>.from(json['followedClubs'] ?? []),
        createdAt: json['createdAt'] != null
            ? (json['createdAt'] as dynamic).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'studentId': studentId,
        'followedClubs': followedClubs,
        'createdAt': createdAt,
      };

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? studentId,
    List<String>? followedClubs,
    DateTime? createdAt,
  }) =>
      AppUser(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        studentId: studentId ?? this.studentId,
        followedClubs: followedClubs ?? this.followedClubs,
        createdAt: createdAt ?? this.createdAt,
      );
}
