import 'package:flutter/material.dart';

/// Kategori seçicilerde ("etkinlik kategorisi", "kayıp eşya türü" gibi)
/// ortak arayüz. `CategoryDropdownField` bu tipi bekler; her feature kendi
/// sabit katalogunu (ör. `EventCategory`, `LostFoundCategory`) bu arayüzü
/// uygulayarak tanımlar, bileşeni kopyalamaz.
abstract class CategoryOption {
  String get id;
  String get label;
  Color get color;
  IconData get icon;
}
