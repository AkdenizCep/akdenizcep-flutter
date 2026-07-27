class ProfileClubSummary {
  final String id;
  final String name;
  final String logoUrl;
  final String category;

  ProfileClubSummary({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.category,
  });

  factory ProfileClubSummary.fromJson(Map<String, dynamic> json) =>
      ProfileClubSummary(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        logoUrl: json['logoUrl'] as String? ?? '',
        category: json['category'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'logoUrl': logoUrl,
    'category': category,
  };

  ProfileClubSummary copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? category,
  }) => ProfileClubSummary(
    id: id ?? this.id,
    name: name ?? this.name,
    logoUrl: logoUrl ?? this.logoUrl,
    category: category ?? this.category,
  );
}
