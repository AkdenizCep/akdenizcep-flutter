class RingSchedule {
  final String lineId;
  final List<String> weekday;
  final List<String> weekend;

  /// Guzergahtaki durak id'leri, kalkis noktasindan varis noktasina dogru sirali.
  /// Universite verisi girilmeden once bos olabilir.
  final List<String> stops;

  RingSchedule({
    required this.lineId,
    required this.weekday,
    required this.weekend,
    this.stops = const [],
  });

  /// "au102_gidis" -> "au102"
  /// Yon ekini atip kalan kismi tek parca hale getirir.
  ///
  /// RTDB anahtarlari iki bicimde de girilebiliyor — "au102_gidis" ve
  /// "au_102_gidis". Ikisi de ayni hatti gosterdigi icin ara alt cizgiler
  /// temizlenir, yoksa "au_102_gidis" hat kodu olarak yalnizca "au" verir ve
  /// tum hatlar tek bir dugmede toplanir.
  String get lineCode {
    var code = lineId.toLowerCase();
    for (final suffix in const ['_gidis', '_donus']) {
      if (code.endsWith(suffix)) {
        code = code.substring(0, code.length - suffix.length);
        break;
      }
    }
    return code.replaceAll('_', '');
  }

  bool get isReturn => lineId.toLowerCase().endsWith('donus');

  factory RingSchedule.fromJson(String lineId, Map<String, dynamic> json) =>
      RingSchedule(
        lineId: lineId,
        weekday: List<String>.from(json['weekday'] ?? []),
        weekend: List<String>.from(json['weekend'] ?? []),
        stops: List<String>.from(json['stops'] ?? []),
      );

  Map<String, dynamic> toJson() => {
    'weekday': weekday,
    'weekend': weekend,
    'stops': stops,
  };

  RingSchedule copyWith({
    String? lineId,
    List<String>? weekday,
    List<String>? weekend,
    List<String>? stops,
  }) => RingSchedule(
    lineId: lineId ?? this.lineId,
    weekday: weekday ?? this.weekday,
    weekend: weekend ?? this.weekend,
    stops: stops ?? this.stops,
  );
}
