import 'package:flutter/material.dart';

/// Gesture navigasyonun alt güvenli alanı zaten ~24'ün altında kalıyor ve
/// bu değer sabit boşluklara (yüzen nav çubuğu, FAB, bildirim) tasarım
/// aşamasında dahil edilmişti. Sabit 3 tuşlu (geri/ana ekran/son
/// uygulamalar) sistem çubuğu olan telefonlarda ise bu alan çok daha
/// büyüyor ve o fazlalığı eklemezsek arayüz elemanları çubuğun arkasında
/// kalıyor. Bu yüzden yalnızca 24'ü aşan kısmı ekstra pay olarak veriyoruz —
/// gesture navigasyonda hiçbir şey değişmez.
double systemNavExtraLift(BuildContext context) {
  final systemNavInset = MediaQuery.paddingOf(context).bottom;
  return (systemNavInset - 24).clamp(0, double.infinity);
}
