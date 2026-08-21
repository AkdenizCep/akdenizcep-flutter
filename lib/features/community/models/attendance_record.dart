/// QR ile kapıda alınan yoklama kaydı — bir öğrencinin bir etkinliğe fiziksel
/// katılımını temsil eder. `attendeeIds` (RSVP/"Katıl" listesi) ile karıştırma:
/// bu ayrı bir alt koleksiyonda, yalnızca kulüp yöneticilerince yazılır.
class AttendanceRecord {
  final String uid;
  final String name;
  final String studentId;
  final DateTime checkedInAt;
  final String recordedBy;

  AttendanceRecord({
    required this.uid,
    required this.name,
    required this.studentId,
    required this.checkedInAt,
    required this.recordedBy,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        uid: json['uid'] as String? ?? '',
        name: json['name'] as String? ?? '',
        studentId: json['studentId'] as String? ?? '',
        checkedInAt: json['checkedInAt'] != null
            ? (json['checkedInAt'] as dynamic).toDate()
            : DateTime.now(),
        recordedBy: json['recordedBy'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'studentId': studentId,
    'checkedInAt': checkedInAt,
    'recordedBy': recordedBy,
  };

  AttendanceRecord copyWith({
    String? uid,
    String? name,
    String? studentId,
    DateTime? checkedInAt,
    String? recordedBy,
  }) => AttendanceRecord(
    uid: uid ?? this.uid,
    name: name ?? this.name,
    studentId: studentId ?? this.studentId,
    checkedInAt: checkedInAt ?? this.checkedInAt,
    recordedBy: recordedBy ?? this.recordedBy,
  );
}
