class ClubEvent {
  final String id;
  final String title;
  final DateTime date;
  final String imageUrl;
  final String location;
  final String description;
  final String category;
  final List<String> attendeeIds;
  final int attendeeCount;
  final int? capacity;
  final bool qrAttendance;
  final DateTime createdAt;

  ClubEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.imageUrl,
    required this.location,
    required this.description,
    required this.createdAt,
    this.category = '',
    this.attendeeIds = const [],
    this.attendeeCount = 0,
    this.capacity,
    this.qrAttendance = false,
  });

  factory ClubEvent.fromJson(Map<String, dynamic> json) {
    final attendeeIds = List<String>.from(json['attendeeIds'] ?? const []);

    return ClubEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      date: json['date'] != null
          ? (json['date'] as dynamic).toDate()
          : DateTime.now(),
      imageUrl: json['imageUrl'] as String? ?? '',
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      attendeeIds: attendeeIds,
      attendeeCount: json['attendeeCount'] as int? ?? attendeeIds.length,
      capacity: json['capacity'] as int?,
      qrAttendance: json['qrAttendance'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'imageUrl': imageUrl,
    'location': location,
    'description': description,
    'category': category,
    'attendeeIds': attendeeIds,
    'attendeeCount': attendeeCount,
    'capacity': capacity,
    'qrAttendance': qrAttendance,
    'createdAt': createdAt,
  };

  ClubEvent copyWith({
    String? id,
    String? title,
    DateTime? date,
    String? imageUrl,
    String? location,
    String? description,
    String? category,
    List<String>? attendeeIds,
    int? attendeeCount,
    int? capacity,
    bool? qrAttendance,
    DateTime? createdAt,
  }) => ClubEvent(
    id: id ?? this.id,
    title: title ?? this.title,
    date: date ?? this.date,
    imageUrl: imageUrl ?? this.imageUrl,
    location: location ?? this.location,
    description: description ?? this.description,
    category: category ?? this.category,
    attendeeIds: attendeeIds ?? this.attendeeIds,
    attendeeCount: attendeeCount ?? this.attendeeCount,
    capacity: capacity ?? this.capacity,
    qrAttendance: qrAttendance ?? this.qrAttendance,
    createdAt: createdAt ?? this.createdAt,
  );
}
