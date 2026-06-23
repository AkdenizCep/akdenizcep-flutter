class MealRating {
  final String id;
  final String mealName;
  final String date;
  final double avgRating;
  final int ratingCount;

  MealRating({
    required this.id,
    required this.mealName,
    required this.date,
    required this.avgRating,
    required this.ratingCount,
  });

  factory MealRating.fromJson(Map<String, dynamic> json) => MealRating(
    id: json['id'] as String? ?? '',
    mealName: json['mealName'] as String? ?? '',
    date: json['date'] as String? ?? '',
    avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
    ratingCount: json['ratingCount'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'mealName': mealName,
    'date': date,
    'avgRating': avgRating,
    'ratingCount': ratingCount,
  };

  MealRating copyWith({
    String? id,
    String? mealName,
    String? date,
    double? avgRating,
    int? ratingCount,
  }) => MealRating(
    id: id ?? this.id,
    mealName: mealName ?? this.mealName,
    date: date ?? this.date,
    avgRating: avgRating ?? this.avgRating,
    ratingCount: ratingCount ?? this.ratingCount,
  );
}
