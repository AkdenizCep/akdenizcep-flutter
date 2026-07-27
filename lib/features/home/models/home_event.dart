class HomeEvent {
  final String id;
  final String title;
  final String authorUid;
  final DateTime date;
  final String location;
  final String description;
  final DateTime createdAt;

  HomeEvent({
    required this.id,
    required this.title,
    required this.authorUid,
    required this.date,
    required this.location,
    required this.description,
    required this.createdAt,
  });

  factory HomeEvent.fromJson(Map<String, dynamic> json) => HomeEvent(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    authorUid: json['authorUid'] as String? ?? '',
    date: json['date'] != null
        ? (json['date'] as dynamic).toDate()
        : DateTime.now(),
    location: json['location'] as String? ?? '',
    description: json['description'] as String? ?? '',
    createdAt: json['createdAt'] != null
        ? (json['createdAt'] as dynamic).toDate()
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'authorUid': authorUid,
    'date': date,
    'location': location,
    'description': description,
    'createdAt': createdAt,
  };

  HomeEvent copyWith({
    String? id,
    String? title,
    String? authorUid,
    DateTime? date,
    String? location,
    String? description,
    DateTime? createdAt,
  }) => HomeEvent(
    id: id ?? this.id,
    title: title ?? this.title,
    authorUid: authorUid ?? this.authorUid,
    date: date ?? this.date,
    location: location ?? this.location,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
  );
}
