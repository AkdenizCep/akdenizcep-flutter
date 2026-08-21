import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/campus_location.dart';

extension MapCategoryStyle on LocationCategory {
  IconData get icon {
    return switch (this) {
      LocationCategory.faculty => Icons.school_outlined,
      LocationCategory.dining => Icons.restaurant_outlined,
      LocationCategory.shopping => Icons.shopping_bag_outlined,
      LocationCategory.sports => Icons.sports_basketball_outlined,
      LocationCategory.library => Icons.local_library_outlined,
      LocationCategory.administrative => Icons.business_outlined,
      LocationCategory.dormitory => Icons.bed_outlined,
      LocationCategory.health => Icons.local_hospital_outlined,
    };
  }

  double get markerHue {
    return switch (this) {
      LocationCategory.faculty => BitmapDescriptor.hueAzure,
      LocationCategory.dining => BitmapDescriptor.hueOrange,
      LocationCategory.shopping => BitmapDescriptor.hueGreen,
      LocationCategory.sports => BitmapDescriptor.hueBlue,
      LocationCategory.library => BitmapDescriptor.hueCyan,
      LocationCategory.administrative => BitmapDescriptor.hueYellow,
      LocationCategory.dormitory => BitmapDescriptor.hueViolet,
      LocationCategory.health => BitmapDescriptor.hueRed,
    };
  }

  Color color(ColorScheme colorScheme) {
    return switch (this) {
      LocationCategory.faculty => colorScheme.primary,
      LocationCategory.dining => colorScheme.secondary,
      LocationCategory.shopping => const Color(0xFF2E7D32),
      LocationCategory.sports => const Color(0xFF1565C0),
      LocationCategory.library => const Color(0xFF00838F),
      LocationCategory.administrative => const Color(0xFFEF6C00),
      LocationCategory.dormitory => const Color(0xFF7B1FA2),
      LocationCategory.health => colorScheme.error,
    };
  }
}
