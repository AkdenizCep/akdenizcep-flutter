class RingSchedule {
  final String lineId;
  final List<String> weekday;
  final List<String> weekend;

  RingSchedule({
    required this.lineId,
    required this.weekday,
    required this.weekend,
  });

  factory RingSchedule.fromJson(String lineId, Map<String, dynamic> json) =>
      RingSchedule(
        lineId: lineId,
        weekday: List<String>.from(json['weekday'] ?? []),
        weekend: List<String>.from(json['weekend'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'weekend': weekend,
      };

  RingSchedule copyWith({
    String? lineId,
    List<String>? weekday,
    List<String>? weekend,
  }) =>
      RingSchedule(
        lineId: lineId ?? this.lineId,
        weekday: weekday ?? this.weekday,
        weekend: weekend ?? this.weekend,
      );
}
