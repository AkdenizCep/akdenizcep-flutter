class ProfileEventSummary {
  final String id;
  final String title;
  final DateTime date;
  final String location;

  ProfileEventSummary({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
  });

  factory ProfileEventSummary.fromJson(Map<String, dynamic> json) =>
      ProfileEventSummary(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        date: json['date'] != null
            ? (json['date'] as dynamic).toDate()
            : DateTime.now(),
        location: json['location'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'location': location,
  };

  ProfileEventSummary copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? location,
  }) => ProfileEventSummary(
    id: id ?? this.id,
    title: title ?? this.title,
    date: date ?? this.date,
    location: location ?? this.location,
  );
}
