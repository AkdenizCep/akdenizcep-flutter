import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Alt navigasyon çubuğunun görünürlüğünü kontrol eder.
/// Bir modal bottom sheet gibi tam ekran alt katman açıldığında
/// nav bar'ın üzerine binmemesi için geçici olarak gizlenir.
final bottomNavVisibleProvider = StateProvider<bool>((_) => true);
