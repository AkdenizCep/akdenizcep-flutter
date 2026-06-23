class AppUser {
  final String id;
  final String name;
  final String email;
  final String studentId;
  final List<String> followedClubs;
  final List<String> ratedMealIds;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.followedClubs,
    this.ratedMealIds = const [],
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    studentId: json['studentId'] as String? ?? '',
    followedClubs: List<String>.from(json['followedClubs'] ?? []),
    ratedMealIds: List<String>.from(json['ratedMealIds'] ?? []),
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
    'ratedMealIds': ratedMealIds,
    'createdAt': createdAt,
  };

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? studentId,
    List<String>? followedClubs,
    List<String>? ratedMealIds,
    DateTime? createdAt,
  }) => AppUser(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    studentId: studentId ?? this.studentId,
    followedClubs: followedClubs ?? this.followedClubs,
    ratedMealIds: ratedMealIds ?? this.ratedMealIds,
    createdAt: createdAt ?? this.createdAt,
  );
}
