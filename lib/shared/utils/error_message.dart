/// Dart'ın `Exception('...')` ile fırlatılan hatalarının `toString()`'i
/// otomatik olarak başına "Exception: " ekliyor; kullanıcıya gösterirken
/// bunu temizler.
String errorMessage(Object error) {
  return error.toString().replaceFirst('Exception: ', '');
}
