/// Öğrencinin QR kodunun içeriğini tek noktada üretip çözer.
///
/// Şu an payload düz öğrenci numarasıdır; ileride imzalı/dönen bir token'a
/// geçilmek istenirse yalnızca bu iki fonksiyon değişir, çağıran taraflar
/// (profil QR ekranı, tarayıcı) etkilenmez.
library;

final _digitsOnly = RegExp(r'^\d+$');

/// Öğrenci numarasından QR'a gömülecek metni üretir.
String encodeStudentQr(String studentId) => studentId.trim();

/// Kameranın okuduğu ham metni öğrenci numarasına çözer. Boş ya da rakam
/// dışı karakter içeren değerler için `null` döner.
String? decodeStudentQr(String? rawScanValue) {
  final value = rawScanValue?.trim() ?? '';
  if (value.isEmpty || !_digitsOnly.hasMatch(value)) return null;
  return value;
}
