class ProfileEventSummary {
  final String id;
  final String title;
  final DateTime date;
  final String location;
  final String? clubId;

  ProfileEventSummary({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    this.clubId,
  });

  factory ProfileEventSummary.fromJson(Map<String, dynamic> json) =>
      ProfileEventSummary(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        date: json['date'] != null
            ? (json['date'] as dynamic).toDate()
            : DateTime.now(),
        location: json['location'] as String? ?? '',
        clubId: json['clubId'] as String?,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'location': location,
    'clubId': clubId,
  };

  ProfileEventSummary copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? location,
    String? clubId,
  }) => ProfileEventSummary(
    id: id ?? this.id,
    title: title ?? this.title,
    date: date ?? this.date,
    location: location ?? this.location,
    clubId: clubId ?? this.clubId,
  );
}
