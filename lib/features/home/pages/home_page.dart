import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const HomePage({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Yemekhane',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(Icons.directions_bus),
            label: 'Ring',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Etkinlikler',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Harita',
          ),
        ],
      ),
    );
  }
}

class HomeContentPage extends ConsumerWidget {
  const HomeContentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akdeniz Cep'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _QuickAccessCard(
            title: 'Yemekhane Menusu',
            icon: Icons.restaurant,
            onTap: () => context.go('/cafeteria'),
          ),
          _QuickAccessCard(
            title: 'Ring Saatleri',
            icon: Icons.directions_bus,
            onTap: () => context.go('/ring'),
          ),
          _QuickAccessCard(
            title: 'Ogrenci Etkinlikleri',
            icon: Icons.event,
            onTap: () => context.go('/student-events'),
          ),
          _QuickAccessCard(
            title: 'Kulupler',
            icon: Icons.groups,
            onTap: () => context.go('/home/community'),
          ),
          _QuickAccessCard(
            title: 'Ilan Panosu',
            icon: Icons.dashboard,
            onTap: () => context.go('/home/board'),
          ),
          _QuickAccessCard(
            title: 'Kampus Haritasi',
            icon: Icons.map,
            onTap: () => context.go('/map'),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
