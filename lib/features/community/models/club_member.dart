/// Bir topluluğun yönetici üyesi — kulüp başkanının öğrenci numarasıyla
/// eklediği kişi. `addedAt`, üye arama sonucunda henüz eklenmemiş bir kişiyi
/// temsil ederken `null` olabilir.
class ClubMember {
  final String uid;
  final String name;
  final String studentId;
  final DateTime? addedAt;

  ClubMember({
    required this.uid,
    required this.name,
    required this.studentId,
    this.addedAt,
  });

  factory ClubMember.fromJson(Map<String, dynamic> json) => ClubMember(
    uid: json['uid'] as String? ?? '',
    name: json['name'] as String? ?? '',
    studentId: json['studentId'] as String? ?? '',
    addedAt: json['addedAt'] != null
        ? (json['addedAt'] as dynamic).toDate()
        : null,
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'studentId': studentId,
    'addedAt': addedAt,
  };

  ClubMember copyWith({
    String? uid,
    String? name,
    String? studentId,
    DateTime? addedAt,
  }) => ClubMember(
    uid: uid ?? this.uid,
    name: name ?? this.name,
    studentId: studentId ?? this.studentId,
    addedAt: addedAt ?? this.addedAt,
  );
}
