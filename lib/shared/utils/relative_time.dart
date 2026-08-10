import 'package:intl/intl.dart';

/// "Şimdi / N dk önce / N saat önce / N gün önce / 12 Mart" biçiminde
/// göreli zaman. Etkinlik kartları ve yorumlar aynı ölçeği kullanır.
String relativeTime(DateTime time) {
  final difference = DateTime.now().difference(time);

  if (difference.inMinutes < 1) return 'Şimdi';
  if (difference.inMinutes < 60) return '${difference.inMinutes} dk önce';
  if (difference.inHours < 24) return '${difference.inHours} saat önce';
  if (difference.inDays < 7) return '${difference.inDays} gün önce';

  return DateFormat('d MMMM', 'tr').format(time);
}
