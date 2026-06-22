import 'package:cloud_firestore/cloud_firestore.dart';

class MealReview {
  final String uid;
  final int rating;
  final String comment;
  final String authorName;
  final DateTime createdAt;

  /// Oy verenin uid'sinden 1 (faydalı) veya -1 (faydasız) değerine eşleme.
  final Map<String, int> votes;

  MealReview({
    required this.uid,
    required this.rating,
    required this.comment,
    required this.authorName,
    required this.createdAt,
    this.votes = const {},
  });

  /// Toplam net puan (upvote - downvote). Yorumları sıralamak için kullanılır.
  int get score => votes.values.fold(0, (total, v) => total + v);

  int get upvoteCount => votes.values.where((v) => v > 0).length;

  int get downvoteCount => votes.values.where((v) => v < 0).length;

  /// Belirtilen kullanıcının bu yoruma verdiği oy: 1, -1 veya 0 (oy yok).
  int voteOf(String voterUid) => votes[voterUid] ?? 0;

  factory MealReview.fromJson(Map<String, dynamic> json) => MealReview(
    uid: json['uid'] as String? ?? '',
    rating: json['rating'] as int? ?? 0,
    comment: json['comment'] as String? ?? '',
    authorName: json['authorName'] as String? ?? '',
    createdAt: json['createdAt'] is Timestamp
        ? (json['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
    votes:
        (json['votes'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ) ??
        const {},
  );

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'rating': rating,
    'comment': comment,
    'authorName': authorName,
    'createdAt': createdAt,
    'votes': votes,
  };

  MealReview copyWith({
    String? uid,
    int? rating,
    String? comment,
    String? authorName,
    DateTime? createdAt,
    Map<String, int>? votes,
  }) => MealReview(
    uid: uid ?? this.uid,
    rating: rating ?? this.rating,
    comment: comment ?? this.comment,
    authorName: authorName ?? this.authorName,
    createdAt: createdAt ?? this.createdAt,
    votes: votes ?? this.votes,
  );
}
