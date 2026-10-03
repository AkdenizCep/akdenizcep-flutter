import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/components/akdeniz_cep_logo.dart';
import '../../../shared/components/app_top_bar.dart';
import '../../../shared/components/error_view.dart';
import '../../../shared/components/loading_overlay.dart';
import '../../../shared/providers/nav_visibility_provider.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/utils/system_nav_inset.dart';
import '../providers/home_provider.dart';
import '../providers/quick_actions_provider.dart';
import 'components/announcement_slider.dart';
import 'components/event_card.dart';
import 'components/quick_action_launcher.dart';
import 'components/quick_actions_edit_sheet.dart';
import 'components/quick_actions_grid.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final extraLift = systemNavExtraLift(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.10),
            theme.colorScheme.primary.withValues(alpha: 0.03),
            Colors.transparent,
          ],
          stops: const [0.0, 0.45, 0.85],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + extraLift),
        // Dis katman yalnizca golge (elevation) verir; ic katman bulanik cam.
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.14),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  color:
                      (isDark
                              ? theme.colorScheme.surfaceContainerHigh
                              : theme.colorScheme.surface)
                          .withValues(alpha: isDark ? 0.45 : 0.55),
                  borderRadius: BorderRadius.circular(36),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                    width: 1.2,
                  ),
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.45),
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                            // Interactive items layer
                            Row(
                              children: [
                                _navItem(
                                  context,
                                  HugeIcons.strokeRoundedHome01,
                                  0,
                                ),
                                _navItem(
                                  context,
                                  HugeIcons.strokeRoundedRestaurant01,
                                  1,
                                ),
                                _navItem(
                                  context,
                                  HugeIcons.strokeRoundedBus01,
                                  2,
                                ),
                                _navItem(
                                  context,
                                  HugeIcons.strokeRoundedUserGroup,
                                  3,
                                ),
                                _navItem(
                                  context,
                                  HugeIcons.strokeRoundedUniversity,
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
          ),
        ),
      ),
    );
  }

  // Hugeicons ucretsiz paketi yalnizca stroke stilinde; secili sekme daha
  // kalin cizgiyle ayirt edilir.
  Widget _navItem(BuildContext context, List<List<dynamic>> icon, int index) {
    final isSelected = widget.currentIndex == index;
    return _navSlot(
      context,
      index,
      (color) => HugeIcon(
        icon: icon,
        color: color,
        size: 24,
        strokeWidth: isSelected ? 2.2 : 1.5,
      ),
    );
  }

  Widget _navSlot(
    BuildContext context,
    int index,
    Widget Function(Color? color) iconBuilder,
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
            builder: (context, color, child) => iconBuilder(color),
          ),
        ),
      ),
    );
  }
}

class HomeContentPage extends ConsumerWidget {
  const HomeContentPage({super.key});

  Future<void> _editQuickActions(BuildContext context, WidgetRef ref) async {
    final edited = await showQuickActionsEditSheet(
      context,
      ref.read(quickActionsProvider),
    );
    if (edited == null || !context.mounted) return;
    await ref.read(quickActionsProvider.notifier).setActions(edited);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final announcementsAsync = ref.watch(announcementsProvider);
    final eventsAsync = ref.watch(recommendedHomeEventsProvider);
    final quickActions = ref.watch(quickActionsProvider);
    final userInitial = userAsync.valueOrNull?.name.isNotEmpty == true
        ? userAsync.valueOrNull!.name[0].toUpperCase()
        : '?';
    final greetingStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 110 + systemNavExtraLift(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header — Home'da bilinçli istisna: logo ve avatar tek satırda,
              // sayfa adı yok. AppTopBar ile aynı margin ve hizada (52px satır yüksekliği).
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  kTopBarHPad,
                  4,
                  kTopBarHPad,
                  6,
                ),
                child: SizedBox(
                  height: kTopBarRowHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const AkdenizCepLogo(fontSize: 24),
                      AppTopBarAction.avatar(
                        initial: userInitial,
                        imageUrl: userAsync.valueOrNull?.photoUrl,
                        onTap: () => context.push('/profile'),
                      ),
                    ],
                  ),
                ),
              ),

              // Greeting
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    userAsync.when(
                      data: (user) => Text(
                        'Merhaba, ${user?.name.split(' ').first ?? 'Öğrenci'} 👋',
                        style: greetingStyle,
                      ),
                      loading: () => Text('Merhaba 👋', style: greetingStyle),
                      error: (error, stackTrace) =>
                          Text('Merhaba 👋', style: greetingStyle),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kampüste bugün neler var?',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

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

              const SizedBox(height: 10),

              // Quick Access (başlık, "Düzenle" ve kullanıcının seçtiği 3x2 ızgara)
              QuickActionsGrid(
                actions: quickActions,
                onSelected: (action) => openQuickAction(context, action),
                onEdit: () => _editQuickActions(context, ref),
              ),

              const SizedBox(height: 10),

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
                      onPressed: () => context.go('/events'),
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
                          onTap: () => context.push(
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
