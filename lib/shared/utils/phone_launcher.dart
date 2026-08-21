import 'package:url_launcher/url_launcher.dart';

Future<bool> launchPhoneCall(String phoneNumber) async {
  final normalizedNumber = phoneNumber.replaceAll(RegExp(r'[^+\d]'), '');
  try {
    return await launchUrl(
      Uri(scheme: 'tel', path: normalizedNumber),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}
