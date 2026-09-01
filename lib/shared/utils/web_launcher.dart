import 'package:url_launcher/url_launcher.dart';

Future<bool> launchInAppBrowser(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') return false;

  try {
    final launched = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (launched) return true;
  } catch (_) {
    // Desteklenmeyen cihazlarda harici tarayıcı yedeğine geçilir.
  }

  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
