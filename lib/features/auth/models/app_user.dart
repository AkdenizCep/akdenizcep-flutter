class AppUser {
  final String id;
  final String name;
  final String email;
  final String studentId;
  final String photoUrl;
  final List<String> followedClubs;
  final List<String> ratedMealIds;
  final List<String> savedEventIds;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    this.photoUrl = '',
    required this.followedClubs,
    this.ratedMealIds = const [],
    this.savedEventIds = const [],
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    studentId: json['studentId'] as String? ?? '',
    photoUrl: json['photoUrl'] as String? ?? '',
    followedClubs: List<String>.from(json['followedClubs'] ?? []),
    ratedMealIds: List<String>.from(json['ratedMealIds'] ?? []),
    savedEventIds: List<String>.from(json['savedEventIds'] ?? []),
    createdAt: json['createdAt'] != null
        ? (json['createdAt'] as dynamic).toDate()
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'studentId': studentId,
    'photoUrl': photoUrl,
    'followedClubs': followedClubs,
    'ratedMealIds': ratedMealIds,
    'savedEventIds': savedEventIds,
    'createdAt': createdAt,
  };

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? studentId,
    String? photoUrl,
    List<String>? followedClubs,
    List<String>? ratedMealIds,
    List<String>? savedEventIds,
    DateTime? createdAt,
  }) => AppUser(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    studentId: studentId ?? this.studentId,
    photoUrl: photoUrl ?? this.photoUrl,
    followedClubs: followedClubs ?? this.followedClubs,
    ratedMealIds: ratedMealIds ?? this.ratedMealIds,
    savedEventIds: savedEventIds ?? this.savedEventIds,
    createdAt: createdAt ?? this.createdAt,
  );
}
