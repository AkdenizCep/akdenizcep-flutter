import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../models/quick_action.dart';

/// Kısayolun vurgu rengi; gerçek renk tema şemasından çözülür, böylece açık ve
/// koyu temada ayrı ayrı ayarlanmış tonlar kullanılır.
enum QuickActionTone { primary, secondary, tertiary, error }

extension QuickActionStyle on QuickAction {
  FaIconData get icon {
    return switch (this) {
      QuickAction.obs => FontAwesomeIcons.graduationCap,
      QuickAction.campusCard => FontAwesomeIcons.wallet,
      QuickAction.academicCalendar => FontAwesomeIcons.calendarDays,
      QuickAction.campusSecurity => FontAwesomeIcons.phone,
      QuickAction.chatbot => FontAwesomeIcons.robot,
      QuickAction.mediko => FontAwesomeIcons.userDoctor,
      QuickAction.campusMap => FontAwesomeIcons.mapLocationDot,
      QuickAction.lostFound => FontAwesomeIcons.boxOpen,
      QuickAction.campusPhotos => FontAwesomeIcons.images,
      QuickAction.emergencyContacts => FontAwesomeIcons.phoneVolume,
    };
  }

  QuickActionTone get tone {
    return switch (this) {
      QuickAction.campusCard => QuickActionTone.secondary,
      QuickAction.chatbot || QuickAction.mediko => QuickActionTone.tertiary,
      QuickAction.campusSecurity ||
      QuickAction.emergencyContacts => QuickActionTone.error,
      QuickAction.obs ||
      QuickAction.academicCalendar ||
      QuickAction.campusMap ||
      QuickAction.lostFound ||
      QuickAction.campusPhotos => QuickActionTone.primary,
    };
  }

  Color accent(ColorScheme colorScheme) {
    return switch (tone) {
      QuickActionTone.primary => colorScheme.primary,
      QuickActionTone.secondary => colorScheme.secondary,
      QuickActionTone.tertiary => colorScheme.tertiary,
      QuickActionTone.error => colorScheme.error,
    };
  }
}
