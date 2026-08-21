import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'components/campus_header.dart';
import 'components/campus_service_group.dart';

class CampusPage extends StatelessWidget {
  const CampusPage({super.key});

  void _showPreparingMessage(BuildContext context, String title) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$title sayfası hazırlanıyor.'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final campusServices = [
      CampusServiceDestination(
        title: 'Kampüs Haritası',
        description: 'Binalar, kapılar ve önemli noktalar',
        icon: Icons.location_on_outlined,
        onTap: () => context.go('/campus/map'),
      ),
      CampusServiceDestination(
        title: 'Kayıp & Buluntu',
        description: 'İlanları incele veya yeni ilan oluştur',
        icon: Icons.inventory_2_outlined,
        onTap: () => _showPreparingMessage(context, 'Kayıp & Buluntu'),
      ),
      CampusServiceDestination(
        title: 'Kampüs Fotoğrafları',
        description: 'Kampüsten paylaşılan kareleri keşfet',
        icon: Icons.photo_library_outlined,
        onTap: () => _showPreparingMessage(context, 'Kampüs Fotoğrafları'),
      ),
    ];
    final safetyServices = [
      CampusServiceDestination(
        title: 'Acil Numaralar',
        description: 'Güvenlik birimleri ve nöbet noktaları',
        icon: Icons.phone_in_talk_outlined,
        tone: CampusServiceTone.alert,
        onTap: () => context.go('/campus/emergency-contacts'),
      ),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            132 + MediaQuery.of(context).padding.bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CampusHeader(),
                  const SizedBox(height: 20),
                  const CampusSectionTitle(title: 'Kampüs Yaşamı'),
                  const SizedBox(height: 10),
                  CampusServiceGroup(destinations: campusServices),
                  const SizedBox(height: 28),
                  const CampusSectionTitle(title: 'Yardım ve Güvenlik'),
                  const SizedBox(height: 10),
                  CampusServiceGroup(destinations: safetyServices),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
