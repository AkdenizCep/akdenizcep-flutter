class StudentEvent {
  final String id;
  final String title;
  final String authorUid;
  final String authorName;
  final DateTime date;
  final String location;
  final double? locationLatitude;
  final double? locationLongitude;
  final String description;
  final String imageUrl;
  final String category;
  final List<String> attendeeIds;
  final int attendeeCount;
  final int? capacity;
  final DateTime createdAt;

  StudentEvent({
    required this.id,
    required this.title,
    required this.authorUid,
    required this.date,
    required this.location,
    required this.description,
    required this.createdAt,
    this.locationLatitude,
    this.locationLongitude,
    this.authorName = '',
    this.imageUrl = '',
    this.category = '',
    this.attendeeIds = const [],
    this.attendeeCount = 0,
    this.capacity,
  });

  factory StudentEvent.fromJson(Map<String, dynamic> json) {
    final attendeeIds = List<String>.from(json['attendeeIds'] ?? const []);

    return StudentEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      authorUid: json['authorUid'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      date: json['date'] != null
          ? (json['date'] as dynamic).toDate()
          : DateTime.now(),
      location: json['location'] as String? ?? '',
      locationLatitude: (json['locationLatitude'] as num?)?.toDouble(),
      locationLongitude: (json['locationLongitude'] as num?)?.toDouble(),
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      category: json['category'] as String? ?? '',
      attendeeIds: attendeeIds,
      attendeeCount: json['attendeeCount'] as int? ?? attendeeIds.length,
      capacity: json['capacity'] as int?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'authorUid': authorUid,
    'authorName': authorName,
    'date': date,
    'location': location,
    'locationLatitude': locationLatitude,
    'locationLongitude': locationLongitude,
    'description': description,
    'imageUrl': imageUrl,
    'category': category,
    'attendeeIds': attendeeIds,
    'attendeeCount': attendeeCount,
    'capacity': capacity,
    'createdAt': createdAt,
  };

  StudentEvent copyWith({
    String? id,
    String? title,
    String? authorUid,
    String? authorName,
    DateTime? date,
    String? location,
    double? locationLatitude,
    double? locationLongitude,
    String? description,
    String? imageUrl,
    String? category,
    List<String>? attendeeIds,
    int? attendeeCount,
    int? capacity,
    DateTime? createdAt,
  }) => StudentEvent(
    id: id ?? this.id,
    title: title ?? this.title,
    authorUid: authorUid ?? this.authorUid,
    authorName: authorName ?? this.authorName,
    date: date ?? this.date,
    location: location ?? this.location,
    locationLatitude: locationLatitude ?? this.locationLatitude,
    locationLongitude: locationLongitude ?? this.locationLongitude,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    category: category ?? this.category,
    attendeeIds: attendeeIds ?? this.attendeeIds,
    attendeeCount: attendeeCount ?? this.attendeeCount,
    capacity: capacity ?? this.capacity,
    createdAt: createdAt ?? this.createdAt,
  );
}
