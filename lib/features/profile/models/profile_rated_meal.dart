class ProfileRatedMeal {
  final String date;
  final String mealName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  ProfileRatedMeal({
    required this.date,
    required this.mealName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ProfileRatedMeal.fromJson(Map<String, dynamic> json) =>
      ProfileRatedMeal(
        date: json['date'] as String? ?? '',
        mealName: json['mealName'] as String? ?? '',
        rating: json['rating'] as int? ?? 0,
        comment: json['comment'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? (json['createdAt'] as dynamic).toDate()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'date': date,
    'mealName': mealName,
    'rating': rating,
    'comment': comment,
    'createdAt': createdAt,
  };

  ProfileRatedMeal copyWith({
    String? date,
    String? mealName,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) => ProfileRatedMeal(
    date: date ?? this.date,
    mealName: mealName ?? this.mealName,
    rating: rating ?? this.rating,
    comment: comment ?? this.comment,
    createdAt: createdAt ?? this.createdAt,
  );
}
