/// Kullanicinin bir gunun menusune verdigi puan.
/// Ogun ayrimi kaldirildigi icin kayit gun bazlidir.
class ProfileRatedMeal {
  /// "YYYY-MM-DD"
  final String date;
  final int rating;
  final String comment;
  final DateTime createdAt;

  ProfileRatedMeal({
    required this.date,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ProfileRatedMeal.fromJson(Map<String, dynamic> json) =>
      ProfileRatedMeal(
        date: json['date'] as String? ?? '',
        rating: json['rating'] as int? ?? 0,
        comment: json['comment'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? (json['createdAt'] as dynamic).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'date': date,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt,
  };

  ProfileRatedMeal copyWith({
    String? date,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) => ProfileRatedMeal(
    date: date ?? this.date,
    rating: rating ?? this.rating,
    comment: comment ?? this.comment,
    createdAt: createdAt ?? this.createdAt,
  );
}
