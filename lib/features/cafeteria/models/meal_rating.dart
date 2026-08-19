/// Bir gunun menusune verilen puanlarin ozeti.
/// Dokuman kimligi tarihin kendisidir ("YYYY-MM-DD").
class MealRating {
  final String date;
  final double avgRating;
  final int ratingCount;

  MealRating({
    required this.date,
    required this.avgRating,
    required this.ratingCount,
  });

  factory MealRating.fromJson(Map<String, dynamic> json) => MealRating(
    date: json['date'] as String? ?? '',
    avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
    ratingCount: json['ratingCount'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'date': date,
    'avgRating': avgRating,
    'ratingCount': ratingCount,
  };

  MealRating copyWith({String? date, double? avgRating, int? ratingCount}) =>
      MealRating(
        date: date ?? this.date,
        avgRating: avgRating ?? this.avgRating,
        ratingCount: ratingCount ?? this.ratingCount,
      );
}
