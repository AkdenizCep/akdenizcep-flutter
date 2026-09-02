import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/app_top_bar.dart';
import '../../../shared/providers/user_provider.dart';
import 'components/campus_header.dart';
import 'components/campus_service_group.dart';

class CampusPage extends ConsumerWidget {
  const CampusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final userInitial = userAsync.valueOrNull?.name.isNotEmpty == true
        ? userAsync.valueOrNull!.name[0].toUpperCase()
        : '?';
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
        onTap: () => context.go('/campus/lost-found'),
      ),
      CampusServiceDestination(
        title: 'Kampüs Fotoğrafları',
        description: 'Kampüsten paylaşılan kareleri keşfet',
        icon: Icons.photo_library_outlined,
        onTap: () => context.go('/campus/photos'),
      ),
      CampusServiceDestination(
        title: 'Akademik Takvim',
        description: 'Kayıt, sınav ve tatil tarihleri',
        icon: Icons.event_note_outlined,
        onTap: () => context.go('/campus/academic-calendar'),
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
            0,
            0,
            0,
            132 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CampusHeader(
                actions: [
                  AppTopBarAction.avatar(
                    initial: userInitial,
                    imageUrl: userAsync.valueOrNull?.photoUrl,
                    onTap: () => context.push('/profile'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: kTopBarHPad),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
            ],
          ),
        ),
      ),
    );
  }
}
