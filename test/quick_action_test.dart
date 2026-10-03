import 'package:akdenizcep/features/home/models/quick_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuickAction', () {
    test('varsayilan liste tam 6 benzersiz ogeden olusur', () {
      expect(kDefaultQuickActions, hasLength(kQuickActionSlotCount));
      expect(kDefaultQuickActions.toSet(), hasLength(kQuickActionSlotCount));
    });

    test('varsayilan sira OBS, TL, takvim, guvenlik, chatbot, mediko', () {
      expect(kDefaultQuickActions, [
        QuickAction.obs,
        QuickAction.campusCard,
        QuickAction.academicCalendar,
        QuickAction.campusSecurity,
        QuickAction.chatbot,
        QuickAction.mediko,
      ]);
    });

    test('fromId bilinen id icin ogeyi, bilinmeyen id icin null doner', () {
      expect(QuickAction.fromId('chatbot'), QuickAction.chatbot);
      expect(QuickAction.fromId('campusMap'), QuickAction.campusMap);
      expect(QuickAction.fromId('yok-boyle-bir-sey'), isNull);
      expect(QuickAction.fromId(''), isNull);
    });

    test('her oge baslik ve aciklamaya sahiptir', () {
      for (final action in QuickAction.values) {
        expect(action.title, isNotEmpty, reason: action.name);
        expect(action.description, isNotEmpty, reason: action.name);
      }
    });
  });

  group('normalizeQuickActions', () {
    test('null (hic kayit yok) varsayilanlari verir', () {
      expect(normalizeQuickActions(null), kDefaultQuickActions);
    });

    test('bos liste varsayilanlari verir', () {
      expect(normalizeQuickActions(const []), kDefaultQuickActions);
    });

    test('gecerli 6 ogenin sirasini korur', () {
      final stored = [
        'campusMap',
        'obs',
        'mediko',
        'chatbot',
        'lostFound',
        'emergencyContacts',
      ];

      expect(normalizeQuickActions(stored), [
        QuickAction.campusMap,
        QuickAction.obs,
        QuickAction.mediko,
        QuickAction.chatbot,
        QuickAction.lostFound,
        QuickAction.emergencyContacts,
      ]);
    });

    test('bilinmeyen id atilir ve liste varsayilanlardan tamamlanir', () {
      final result = normalizeQuickActions([
        'campusMap',
        'silinmis-oge',
        'lostFound',
      ]);

      expect(result, hasLength(kQuickActionSlotCount));
      expect(result.take(2), [QuickAction.campusMap, QuickAction.lostFound]);
      expect(result.toSet(), hasLength(kQuickActionSlotCount));
      // Tamamlama varsayilan siradan, zaten secili olanlari atlayarak yapilir.
      expect(result.skip(2), [
        QuickAction.obs,
        QuickAction.campusCard,
        QuickAction.academicCalendar,
        QuickAction.campusSecurity,
      ]);
    });

    test('tekrar eden id ilk gectigi yerde tutulur', () {
      final result = normalizeQuickActions([
        'obs',
        'chatbot',
        'obs',
        'chatbot',
        'mediko',
        'campusMap',
        'lostFound',
      ]);

      expect(result, [
        QuickAction.obs,
        QuickAction.chatbot,
        QuickAction.mediko,
        QuickAction.campusMap,
        QuickAction.lostFound,
        QuickAction.campusCard,
      ]);
    });

    test('6dan fazla gecerli oge kesilir', () {
      final result = normalizeQuickActions(
        QuickAction.values.map((a) => a.name).toList(),
      );

      expect(result, hasLength(kQuickActionSlotCount));
      expect(result, QuickAction.values.take(kQuickActionSlotCount));
    });

    test('tamamen gecersiz kayit varsayilanlara duser', () {
      expect(normalizeQuickActions(['a', 'b', 'c']), kDefaultQuickActions);
    });
  });
}
