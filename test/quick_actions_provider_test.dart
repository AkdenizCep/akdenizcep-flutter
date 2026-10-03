import 'package:akdenizcep/features/home/models/quick_action.dart';
import 'package:akdenizcep/features/home/providers/quick_actions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'home_quick_actions';

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('disk okumasi bitmeden varsayilan izgara gorunur', () {
    final container = _container();

    expect(container.read(quickActionsProvider), kDefaultQuickActions);
  });

  test('kayit yoksa varsayilan izgara korunur', () async {
    final container = _container();
    container.read(quickActionsProvider);
    await pumpEventQueue();

    expect(container.read(quickActionsProvider), kDefaultQuickActions);
  });

  test('kayitli secim acilista yuklenir', () async {
    SharedPreferences.setMockInitialValues({
      _prefsKey: [
        'campusMap',
        'obs',
        'mediko',
        'chatbot',
        'lostFound',
        'emergencyContacts',
      ],
    });
    final container = _container();
    container.read(quickActionsProvider);
    await pumpEventQueue();

    expect(container.read(quickActionsProvider), [
      QuickAction.campusMap,
      QuickAction.obs,
      QuickAction.mediko,
      QuickAction.chatbot,
      QuickAction.lostFound,
      QuickAction.emergencyContacts,
    ]);
  });

  test('kayittaki bilinmeyen id varsayilanlarla tamamlanir', () async {
    SharedPreferences.setMockInitialValues({
      _prefsKey: ['campusMap', 'silinmis-oge'],
    });
    final container = _container();
    container.read(quickActionsProvider);
    await pumpEventQueue();

    final state = container.read(quickActionsProvider);
    expect(state, hasLength(kQuickActionSlotCount));
    expect(state.first, QuickAction.campusMap);
    expect(state.toSet(), hasLength(kQuickActionSlotCount));
  });

  test('bozuk kayit acilisi bozmaz, varsayilanda kalir', () async {
    SharedPreferences.setMockInitialValues({_prefsKey: 'liste-degil'});
    final container = _container();
    container.read(quickActionsProvider);
    await pumpEventQueue();

    expect(container.read(quickActionsProvider), kDefaultQuickActions);
  });

  test('setActions state i gunceller ve diske yazar', () async {
    final container = _container();
    container.read(quickActionsProvider);
    await pumpEventQueue();

    final next = [
      QuickAction.campusPhotos,
      QuickAction.obs,
      QuickAction.chatbot,
      QuickAction.mediko,
      QuickAction.campusMap,
      QuickAction.academicCalendar,
    ];
    await container.read(quickActionsProvider.notifier).setActions(next);

    expect(container.read(quickActionsProvider), next);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(_prefsKey), next.map((a) => a.name).toList());
  });

  test('setActions eksik listeyi 6ya tamamlar', () async {
    final container = _container();
    container.read(quickActionsProvider);
    await pumpEventQueue();

    await container.read(quickActionsProvider.notifier).setActions([
      QuickAction.campusMap,
      QuickAction.lostFound,
    ]);

    final state = container.read(quickActionsProvider);
    expect(state, hasLength(kQuickActionSlotCount));
    expect(state.take(2), [QuickAction.campusMap, QuickAction.lostFound]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList(_prefsKey), state.map((a) => a.name).toList());
  });

  test('kaydedilen secim yeni bir container da geri yuklenir', () async {
    final first = _container();
    first.read(quickActionsProvider);
    await pumpEventQueue();
    final next = [
      QuickAction.emergencyContacts,
      QuickAction.lostFound,
      QuickAction.campusPhotos,
      QuickAction.campusMap,
      QuickAction.obs,
      QuickAction.chatbot,
    ];
    await first.read(quickActionsProvider.notifier).setActions(next);

    final second = _container();
    second.read(quickActionsProvider);
    await pumpEventQueue();

    expect(second.read(quickActionsProvider), next);
  });
}
