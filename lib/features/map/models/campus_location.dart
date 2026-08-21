enum LocationCategory {
  faculty('faculty', 'Fakülteler'),
  dining('dining', 'Yemek & Cafe'),
  shopping('shopping', 'Alışveriş'),
  sports('sports', 'Spor'),
  library('library', 'Kütüphane'),
  administrative('administrative', 'İdari'),
  dormitory('dormitory', 'Yurt'),
  health('health', 'Sağlık');

  const LocationCategory(this.id, this.label);

  final String id;
  final String label;

  static LocationCategory fromId(String id) {
    return LocationCategory.values.firstWhere(
      (category) => category.id == id || category.name == id,
      orElse: () => LocationCategory.faculty,
    );
  }
}

class CampusLocation {
  final String id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final LocationCategory category;
  final String? phoneNumber;
  final String? workingHours;
  final List<String> services;

  const CampusLocation({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.category,
    this.phoneNumber,
    this.workingHours,
    this.services = const [],
  });

  factory CampusLocation.fromJson(Map<String, dynamic> json) {
    return CampusLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      category: LocationCategory.fromId(json['category'] as String),
      phoneNumber: json['phoneNumber'] as String?,
      workingHours: json['workingHours'] as String?,
      services:
          (json['services'] as List<dynamic>?)
              ?.map((service) => service as String)
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'category': category.id,
      'phoneNumber': phoneNumber,
      'workingHours': workingHours,
      'services': services,
    };
  }

  CampusLocation copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    LocationCategory? category,
    String? phoneNumber,
    String? workingHours,
    List<String>? services,
  }) {
    return CampusLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      workingHours: workingHours ?? this.workingHours,
      services: services ?? this.services,
    );
  }
}
