/// Etkinliğin hangi koleksiyondan geldiğini belirtir.
enum EventSource { club, student }

/// Bir etkinliğin hangi dokümanda durduğunu tarif eden adres.
///
/// `StreamProvider.family` anahtarı olarak kullanıldığı için `==`/`hashCode`
/// override edilmiştir; aksi halde her build yeni bir stream açardı.
class EventRef {
  final EventSource source;

  /// Yalnızca [EventSource.club] için dolu.
  final String? clubId;
  final String eventId;

  const EventRef({required this.source, required this.eventId, this.clubId});

  const EventRef.student(this.eventId)
    : source = EventSource.student,
      clubId = null;

  const EventRef.club({required this.clubId, required this.eventId})
    : source = EventSource.club;

  @override
  bool operator ==(Object other) =>
      other is EventRef &&
      other.source == source &&
      other.clubId == clubId &&
      other.eventId == eventId;

  @override
  int get hashCode => Object.hash(source, clubId, eventId);
}

/// Kulüp ve öğrenci etkinliklerinin akışta birleşmiş hâli.
///
/// Feature modellerini (ClubEvent / StudentEvent) sarmalamaz — cross-feature
/// import yasağı nedeniyle doğrudan Firestore verisinden üretilir.
class FeedEvent {
  final String id;
  final EventSource source;
  final String? clubId;
  final String title;
  final DateTime date;
  final String location;
  final double? locationLatitude;
  final double? locationLongitude;
  final String description;
  final String imageUrl;
  final String category;
  final String authorUid;
  final String authorName;
  final String authorLogoUrl;
  final List<String> attendeeIds;
  final int attendeeCount;
  final int? capacity;
  final bool qrAttendance;
  final DateTime createdAt;

  const FeedEvent({
    required this.id,
    required this.source,
    required this.title,
    required this.date,
    required this.location,
    required this.description,
    required this.createdAt,
    this.locationLatitude,
    this.locationLongitude,
    this.clubId,
    this.imageUrl = '',
    this.category = '',
    this.authorUid = '',
    this.authorName = '',
    this.authorLogoUrl = '',
    this.attendeeIds = const [],
    this.attendeeCount = 0,
    this.capacity,
    this.qrAttendance = false,
  });

  EventRef get ref => EventRef(source: source, clubId: clubId, eventId: id);

  bool get isClubEvent =>
      source == EventSource.club || (clubId != null && clubId!.isNotEmpty);

  bool isJoinedBy(String? uid) =>
      uid != null && uid.isNotEmpty && attendeeIds.contains(uid);

  bool get isFull => capacity != null && attendeeCount >= capacity!;

  bool get hasCoordinates =>
      locationLatitude != null && locationLongitude != null;

  bool get hasMappableLocation => hasCoordinates || location.trim().isNotEmpty;

  int? get remainingSeats =>
      capacity == null ? null : (capacity! - attendeeCount).clamp(0, capacity!);

  factory FeedEvent.fromJson(Map<String, dynamic> json) {
    final rawSource = json['source'] as String?;
    final clubId = json['clubId'] as String?;
    final isClub = rawSource == 'club' || (clubId != null && clubId.isNotEmpty);
    final source = isClub ? EventSource.club : EventSource.student;
    final attendeeIds = List<String>.from(json['attendeeIds'] ?? const []);

    return FeedEvent(
      id: json['id'] as String? ?? '',
      source: source,
      clubId: json['clubId'] as String?,
      title: json['title'] as String? ?? '',
      date: _toDate(json['date']),
      location: json['location'] as String? ?? '',
      locationLatitude: (json['locationLatitude'] as num?)?.toDouble(),
      locationLongitude: (json['locationLongitude'] as num?)?.toDouble(),
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      category: json['category'] as String? ?? '',
      authorUid: json['authorUid'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      authorLogoUrl: json['authorLogoUrl'] as String? ?? '',
      attendeeIds: attendeeIds,
      attendeeCount: json['attendeeCount'] as int? ?? attendeeIds.length,
      capacity: json['capacity'] as int?,
      qrAttendance: json['qrAttendance'] as bool? ?? false,
      createdAt: _toDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source == EventSource.club ? 'club' : 'student',
    'clubId': clubId,
    'title': title,
    'date': date,
    'location': location,
    'locationLatitude': locationLatitude,
    'locationLongitude': locationLongitude,
    'description': description,
    'imageUrl': imageUrl,
    'category': category,
    'authorUid': authorUid,
    'authorName': authorName,
    'authorLogoUrl': authorLogoUrl,
    'attendeeIds': attendeeIds,
    'attendeeCount': attendeeCount,
    'capacity': capacity,
    'qrAttendance': qrAttendance,
    'createdAt': createdAt,
  };

  FeedEvent copyWith({
    String? id,
    EventSource? source,
    String? clubId,
    String? title,
    DateTime? date,
    String? location,
    double? locationLatitude,
    double? locationLongitude,
    String? description,
    String? imageUrl,
    String? category,
    String? authorUid,
    String? authorName,
    String? authorLogoUrl,
    List<String>? attendeeIds,
    int? attendeeCount,
    int? capacity,
    bool? qrAttendance,
    DateTime? createdAt,
  }) => FeedEvent(
    id: id ?? this.id,
    source: source ?? this.source,
    clubId: clubId ?? this.clubId,
    title: title ?? this.title,
    date: date ?? this.date,
    location: location ?? this.location,
    locationLatitude: locationLatitude ?? this.locationLatitude,
    locationLongitude: locationLongitude ?? this.locationLongitude,
    description: description ?? this.description,
    imageUrl: imageUrl ?? this.imageUrl,
    category: category ?? this.category,
    authorUid: authorUid ?? this.authorUid,
    authorName: authorName ?? this.authorName,
    authorLogoUrl: authorLogoUrl ?? this.authorLogoUrl,
    attendeeIds: attendeeIds ?? this.attendeeIds,
    attendeeCount: attendeeCount ?? this.attendeeCount,
    capacity: capacity ?? this.capacity,
    qrAttendance: qrAttendance ?? this.qrAttendance,
    createdAt: createdAt ?? this.createdAt,
  );

  static DateTime _toDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return (value as dynamic).toDate() as DateTime;
  }
}
