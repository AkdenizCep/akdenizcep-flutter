import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Duraklar sayfasina gezinme tek bir yerden gecmeli.
///
/// Gecmisi: sayfaya iki ayri butondan gidiliyordu ve her ikisi de gezinmeden
/// once konum istegini `await` ediyordu — bu, acilisi GPS fix suresi kadar
/// geciktiriyordu. Biri duzeltildi, digeri gozden kacti; gecikme surdugu icin
/// tanı iki tur boyunca yanlis yerde arandi.
///
/// Bu test kaynak tarar: yol dizgisi yalnizca [openStopsPage] icinde
/// gecmelidir. Yeni bir giris noktasi eklenirse burada patlar.
void main() {
  test('/ring/stops yoluna yalnizca open_stops_page.dart gezinir', () {
    final offenders = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.endsWith('open_stops_page.dart'))
        .where((file) => file.readAsStringSync().contains("'/ring/stops'"))
        .map((file) => file.path)
        .toList();

    expect(
      offenders,
      isEmpty,
      reason:
          'Duraklar sayfasina dogrudan gezinen dosya(lar) var. Gezinmeyi '
          'openStopsPage() uzerinden yapin — konum istegi gezinmeyi '
          'bloklamamali.',
    );
  });
}
