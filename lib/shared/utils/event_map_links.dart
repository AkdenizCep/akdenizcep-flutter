class EventMapLinks {
  const EventMapLinks._();

  static Uri googleMaps({required double latitude, required double longitude}) {
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$latitude,$longitude',
    });
  }

  static Uri appleMaps({
    required double latitude,
    required double longitude,
    required String title,
  }) {
    return Uri.https('maps.apple.com', '/', {
      'll': '$latitude,$longitude',
      'q': title,
    });
  }

  static Uri googleMapsSearch(String title) {
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$title, Akdeniz Üniversitesi',
    });
  }
}
