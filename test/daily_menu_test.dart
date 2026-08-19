import 'package:akdenizcep/features/cafeteria/models/daily_menu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyMenu.fromRtdb', () {
    test('duz dizi oldugu gibi okunur', () {
      final menu = DailyMenu.fromRtdb('2026-08-04', [
        'Dugun Corbasi',
        'Firinda Makarna',
      ]);

      expect(menu.date, '2026-08-04');
      expect(menu.items, ['Dugun Corbasi', 'Firinda Makarna']);
    });

    test('dugum yoksa bos menu doner', () {
      final menu = DailyMenu.fromRtdb('2026-08-04', null);

      expect(menu.isEmpty, isTrue);
      expect(menu.items, isEmpty);
    });

    test('sayisal anahtarli map dizi sirasina cevrilir', () {
      // RTDB seyrek diziyi map olarak doner; anahtar sirasi garanti degildir.
      final menu = DailyMenu.fromRtdb('2026-08-04', {
        '2': 'Pilav',
        '0': 'Corba',
        '1': 'Kofte',
      });

      expect(menu.items, ['Corba', 'Kofte', 'Pilav']);
    });

    test('on ikiden fazla satirda sayisal siralama alfabetik olmaz', () {
      final menu = DailyMenu.fromRtdb('2026-08-04', {
        '10': 'Onbir',
        '2': 'Uc',
        '1': 'Iki',
      });

      expect(menu.items, ['Iki', 'Uc', 'Onbir']);
    });

    group('eski ogun ayrimli bicim', () {
      test('yalnizca ilk ogun okunur, iki ogun birlestirilmez', () {
        final menu = DailyMenu.fromRtdb('2026-08-04', {
          'dinner': ['Ezogelin Corbasi', 'Izmir Kofte'],
          'lunch': ['Dugun Corbasi', 'Firinda Makarna'],
        });

        expect(menu.items, ['Dugun Corbasi', 'Firinda Makarna']);
      });

      test('kahvalti varsa ogle ve aksamin onune gecer', () {
        final menu = DailyMenu.fromRtdb('2026-08-04', {
          'dinner': ['C'],
          'breakfast': ['A'],
          'lunch': ['B'],
        });

        expect(menu.items, ['A']);
      });

      test('taninmayan ogun anahtari bilinenin arkasinda kalir', () {
        final menu = DailyMenu.fromRtdb('2026-08-04', {
          'gece': ['Z'],
          'lunch': ['A'],
        });

        expect(menu.items, ['A']);
      });

      test('yalnizca taninmayan anahtar varsa o okunur', () {
        final menu = DailyMenu.fromRtdb('2026-08-04', {
          'gece': ['Z'],
        });

        expect(menu.items, ['Z']);
      });

      test('bos map bos menu verir', () {
        expect(DailyMenu.fromRtdb('2026-08-04', <String, Object>{}).isEmpty,
            isTrue);
      });
    });
  });

  group('MenuEntry.parse', () {
    test('kalori soneki ayristirilir', () {
      final entry = MenuEntry.parse('Firinda Makarna - 480 kcal');

      expect(entry.name, 'Firinda Makarna');
      expect(entry.calories, 480);
    });

    test('buyuk harfli kcal de kabul edilir', () {
      expect(MenuEntry.parse('Pilav - 310 KCAL').calories, 310);
    });

    test('kalori yoksa ad oldugu gibi kalir', () {
      final entry = MenuEntry.parse('Zeytinyagli Taze Fasulye');

      expect(entry.name, 'Zeytinyagli Taze Fasulye');
      expect(entry.calories, isNull);
    });

    test('adin icindeki tire kaloriyle karistirilmaz', () {
      final entry = MenuEntry.parse('Kofte - Pilav');

      expect(entry.name, 'Kofte - Pilav');
      expect(entry.calories, isNull);
    });

    test('bastaki ve sondaki bosluklar temizlenir', () {
      expect(MenuEntry.parse('  Cacik  ').name, 'Cacik');
    });
  });

  group('MenuEntry.totalCalories', () {
    test('girilmis kaloriler toplanir', () {
      final entries = [
        MenuEntry.parse('Corba - 210 kcal'),
        MenuEntry.parse('Makarna - 480 kcal'),
      ];

      expect(MenuEntry.totalCalories(entries), 690);
    });

    test('hicbiri girilmemisse null doner', () {
      final entries = [MenuEntry.parse('Corba'), MenuEntry.parse('Makarna')];

      expect(MenuEntry.totalCalories(entries), isNull);
    });

    test('kismen girilmisse yalnizca bilinenler toplanir', () {
      final entries = [
        MenuEntry.parse('Corba - 210 kcal'),
        MenuEntry.parse('Turşu'),
      ];

      expect(MenuEntry.totalCalories(entries), 210);
    });

    test('bos listede null doner', () {
      expect(MenuEntry.totalCalories(const []), isNull);
    });
  });
}
