import 'package:flutter/material.dart';

import '../../../shared/models/category_option.dart';

/// Kayıp/buluntu ilanı için eşya türü kataloğu.
class LostFoundCategory implements CategoryOption {
  @override
  final String id;
  @override
  final String label;
  @override
  final Color color;
  @override
  final IconData icon;

  const LostFoundCategory({
    required this.id,
    required this.label,
    required this.color,
    required this.icon,
  });

  static const electronics = LostFoundCategory(
    id: 'elektronik',
    label: 'Elektronik',
    color: Color(0xFF135BEC),
    icon: Icons.devices_other_rounded,
  );

  static const idCard = LostFoundCategory(
    id: 'kimlik-kart',
    label: 'Kimlik / Kart',
    color: Color(0xFF0F7B8A),
    icon: Icons.badge_outlined,
  );

  static const bagWallet = LostFoundCategory(
    id: 'canta-cuzdan',
    label: 'Çanta / Cüzdan',
    color: Color(0xFF9B6A2F),
    icon: Icons.work_outline_rounded,
  );

  static const keys = LostFoundCategory(
    id: 'anahtar',
    label: 'Anahtar',
    color: Color(0xFFB8860B),
    icon: Icons.key_outlined,
  );

  static const clothing = LostFoundCategory(
    id: 'giyim-aksesuar',
    label: 'Giyim / Aksesuar',
    color: Color(0xFF7B3FF2),
    icon: Icons.checkroom_outlined,
  );

  static const books = LostFoundCategory(
    id: 'kitap-defter',
    label: 'Kitap / Defter',
    color: Color(0xFF168A5B),
    icon: Icons.menu_book_rounded,
  );

  static const other = LostFoundCategory(
    id: 'diger',
    label: 'Diğer',
    color: Color(0xFF64748B),
    icon: Icons.category_outlined,
  );

  static const all = <LostFoundCategory>[
    electronics,
    idCard,
    bagWallet,
    keys,
    clothing,
    books,
    other,
  ];

  /// Firestore'daki `category` id'sinden kataloğu çözer. Eşleşme yoksa
  /// (ör. kategori sonradan kaldırılmışsa) [other]'a düşer.
  static LostFoundCategory resolve(String? id) {
    final normalized = id?.trim().toLowerCase() ?? '';
    for (final category in all) {
      if (category.id == normalized) return category;
    }
    return other;
  }
}
