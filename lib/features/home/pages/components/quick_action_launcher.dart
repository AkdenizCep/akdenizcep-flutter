import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/constants/web_portals.dart';
import '../../../../shared/utils/phone_launcher.dart';
import '../../../../shared/utils/web_launcher.dart';
import '../../models/quick_action.dart';

const _campusSecurityPhone = '02423102222';

/// Kısayolun hedefini açar: uygulama içi sayfa, WebView portalı, tarayıcı ya da
/// arama. Yeni bir [QuickAction] eklenirse derleyici burada eksik kolu işaret
/// eder.
///
/// Kampüs sekmesinin altındaki sayfalar `go` ile açılır (sekme de Kampüs'e
/// geçer); kök navigator sayfaları `push` ile üstüne biner.
Future<void> openQuickAction(BuildContext context, QuickAction action) async {
  switch (action) {
    case QuickAction.obs:
      context.push('/obs');
    case QuickAction.campusCard:
      await _openCampusCard(context);
    case QuickAction.academicCalendar:
      context.push('/academic-calendar');
    case QuickAction.campusSecurity:
      await _callCampusSecurity(context);
    case QuickAction.chatbot:
      context.push('/chatbot');
    case QuickAction.mediko:
      context.push('/mediko');
    case QuickAction.campusMap:
      context.go('/campus/map');
    case QuickAction.lostFound:
      context.go('/campus/lost-found');
    case QuickAction.campusPhotos:
      context.go('/campus/photos');
    case QuickAction.emergencyContacts:
      context.go('/campus/emergency-contacts');
  }
}

Future<void> _openCampusCard(BuildContext context) async {
  final launched = await launchInAppBrowser(campusCardPortalUri);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TL yükleme sayfası açılamadı.')),
    );
  }
}

Future<void> _callCampusSecurity(BuildContext context) async {
  final launched = await launchPhoneCall(_campusSecurityPhone);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Arama uygulaması açılamadı.')),
    );
  }
}
