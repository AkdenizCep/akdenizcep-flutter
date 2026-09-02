import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/akdeniz_cep_logo.dart';
import '../../../shared/components/app_top_bar.dart';
import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/constants/web_portals.dart';
import '../../../shared/providers/nav_visibility_provider.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/phone_launcher.dart';
import '../../../shared/utils/web_launcher.dart';
import '../providers/home_provider.dart';
import 'components/announcement_slider.dart';
import 'components/event_card.dart';

class HomePage extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const HomePage({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navBarVisible = ref.watch(bottomNavVisibleProvider);

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        offset: navBarVisible ? Offset.zero : const Offset(0, 1),
        child: _FloatingNavBar(
          currentIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }
}

class _FloatingNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  @override
  State<_FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<_FloatingNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _previousIndex = 0.0;
  double _currentIndex = 0.0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex.toDouble();
    _currentIndex = widget.currentIndex.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _controller.value = 1.0;
  }

  @override
  void didUpdateWidget(_FloatingNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _previousIndex = _currentIndex;
      _currentIndex = widget.currentIndex.toDouble();
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 0.6, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              const itemCount = 5;
              final slotWidth = totalWidth / itemCount;
              const baseIndicatorWidth = 56.0;
              const indicatorHeight = 48.0;

              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final t = CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeInOutCubic,
                  ).value;

                  final currentPos = Tween<double>(
                    begin: _previousIndex,
                    end: _currentIndex,
                  ).transform(t);

                  final distance = (_currentIndex - _previousIndex).abs();
                  final maxStretch = distance * 0.28;
                  final stretch = 1.0 + maxStretch * (4 * t * (1 - t));

                  final width = baseIndicatorWidth * stretch;
                  final leftOffset =
                      currentPos * slotWidth + (slotWidth - width) / 2;
                  final topOffset =
                      (constraints.maxHeight - indicatorHeight) / 2;

                  return Stack(
                    children: [
                      // Sliding and stretching active indicator background
                      Positioned(
                        left: leftOffset,
                        top: topOffset,
                        width: width,
                        height: indicatorHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                      // Interactive items layer
                      Row(
                        children: [
                          _navItem(context, Icons.home, Icons.home_outlined, 0),
                          _navItem(
                            context,
                            Icons.restaurant,
                            Icons.restaurant_outlined,
                            1,
                          ),
                          _navItem(
                            context,
                            Icons.directions_bus,
                            Icons.directions_bus_outlined,
                            2,
                          ),
                          _navItem(
                            context,
                            Icons.calendar_month,
                            Icons.calendar_month_outlined,
                            3,
                          ),
                          _navItem(
                            context,
                            Icons.location_city_rounded,
                            Icons.location_city_outlined,
                            4,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData selectedIcon,
    IconData icon,
    int index,
  ) {
    final isSelected = widget.currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onDestinationSelected(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: TweenAnimationBuilder<Color?>(
            duration: const Duration(milliseconds: 250),
            tween: ColorTween(
              end: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            builder: (context, color, child) {
              return Icon(
                isSelected ? selectedIcon : icon,
                color: color,
                size: 24,
              );
            },
          ),
        ),
      ),
    );
  }
}

class HomeContentPage extends ConsumerWidget {
  const HomeContentPage({super.key});

  Future<void> _callCampusSecurity(BuildContext context) async {
    final launched = await launchPhoneCall('02423102222');
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arama uygulaması açılamadı.')),
      );
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final announcementsAsync = ref.watch(announcementsProvider);
    final eventsAsync = ref.watch(recommendedHomeEventsProvider);
    final userInitial = userAsync.valueOrNull?.name.isNotEmpty == true
        ? userAsync.valueOrNull!.name[0].toUpperCase()
        : '?';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header — Home'da bilinçli istisna: logo ve avatar tek satırda,
              // sayfa adı yok.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const AkdenizCepLogo(fontSize: 24),
                    AppTopBarAction.avatar(
                      initial: userInitial,
                      onTap: () => context.push('/profile'),
                    ),
                  ],
                ),
              ),

              // Greeting
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    userAsync.when(
                      data: (user) => Text(
                        'Merhaba, ${user?.name.split(' ').first ?? 'Öğrenci'} 👋',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      loading: () => Text(
                        'Merhaba 👋',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      error: (error, stackTrace) => Text(
                        'Merhaba 👋',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kampüste bugün neler var?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Announcements section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Haberler & Duyurular',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/announcements'),
                      child: const Text('Tümünü Gör'),
                    ),
                  ],
                ),
              ),

              // Announcements slider
              announcementsAsync.when(
                data: (announcements) {
                  if (announcements.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        'Henüz duyuru yok.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return AnnouncementSlider(announcements: announcements);
                },
                loading: () =>
                    const SizedBox(height: 200, child: LoadingOverlay()),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: ErrorView(message: errorMessage(e)),
                ),
              ),

              const SizedBox(height: 28),

              // Quick Access header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Hızlı Erişim',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Quick Access grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    _QuickAccessCard(
                      title: 'OBS',
                      subtitle: 'Öğrenci Bilgi Sistemi',
                      icon: Icons.school_outlined,
                      iconColor: Theme.of(context).colorScheme.primary,
                      iconBgColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      onTap: () => context.push('/obs'),
                    ),
                    _QuickAccessCard(
                      title: 'TL Yükleme',
                      subtitle: 'Bakiye İşlemleri',
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: Theme.of(context).colorScheme.secondary,
                      iconBgColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer,
                      onTap: () => _openCampusCard(context),
                    ),
                    _QuickAccessCard(
                      title: 'Akademik\nTakvim',
                      subtitle: 'Önemli Tarihler',
                      icon: Icons.calendar_month_outlined,
                      iconColor: Theme.of(context).colorScheme.primary,
                      iconBgColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      onTap: () => context.go('/campus/academic-calendar'),
                    ),
                    _QuickAccessCard(
                      title: 'Kampüs\nGüvenlik',
                      subtitle: 'Hızlı Arama',
                      icon: Icons.phone_in_talk_rounded,
                      iconColor: Theme.of(context).colorScheme.error,
                      iconBgColor: Theme.of(context).colorScheme.errorContainer,
                      onTap: () => _callCampusSecurity(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Events section header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'İlginizi Çekebilecek Etkinlikler',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/student-events'),
                      child: const Text('Tümünü Gör'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Events horizontal list
              eventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        'Takiplerine uygun yaklaşan etkinlik yok.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return EventCard(
                          event: event,
                          onTap: event.clubId == null
                              ? null
                              : () => context.push(
                                  '/club/${event.clubId}/event/${event.id}',
                                ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 240,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: LoadingOverlay(),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: ErrorView(message: errorMessage(e)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _QuickAccessCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
