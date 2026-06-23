class ClubEvent {
  final String id;
  final String title;
  final DateTime date;
  final String imageUrl;
  final String location;
  final String description;
  final DateTime createdAt;

  ClubEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.imageUrl,
    required this.location,
    required this.description,
    required this.createdAt,
  });

  factory ClubEvent.fromJson(Map<String, dynamic> json) => ClubEvent(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    date: json['date'] != null
        ? (json['date'] as dynamic).toDate()
        : DateTime.now(),
    imageUrl: json['imageUrl'] as String? ?? '',
    location: json['location'] as String? ?? '',
    description: json['description'] as String? ?? '',
    createdAt: json['createdAt'] != null
        ? (json['createdAt'] as dynamic).toDate()
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'imageUrl': imageUrl,
    'location': location,
    'description': description,
    'createdAt': createdAt,
  };

  ClubEvent copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? imageUrl,
    String? location,
    String? description,
    DateTime? createdAt,
  }) => ClubEvent(
    id: id ?? this.id,
    title: title ?? this.title,
    date: date ?? this.date,
    imageUrl: imageUrl ?? this.imageUrl,
    location: location ?? this.location,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
  );
}
