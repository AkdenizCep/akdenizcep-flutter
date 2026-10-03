import 'package:akdenizcep/app/theme.dart';
import 'package:akdenizcep/features/home/models/quick_action.dart';
import 'package:akdenizcep/features/home/pages/components/quick_actions_edit_sheet.dart';
import 'package:akdenizcep/features/home/pages/components/quick_actions_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder _card(QuickAction action) =>
    find.byKey(ValueKey('quick-action-${action.name}'));

Finder _selectedRow(QuickAction action) =>
    find.byKey(ValueKey('selected-${action.name}'));

Finder _removeButton(QuickAction action) =>
    find.byKey(ValueKey('remove-${action.name}'));

Finder _addButton(QuickAction action) =>
    find.byKey(ValueKey('add-${action.name}'));

Finder _dragHandle(QuickAction action) =>
    find.byKey(ValueKey('drag-${action.name}'));

Finder get _saveButton => find.widgetWithText(FilledButton, 'Kaydet');

void _setScreen(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}

void main() {
  group('QuickActionsGrid', () {
    Future<void> pumpGrid(
      WidgetTester tester, {
      List<QuickAction> actions = kDefaultQuickActions,
      ValueChanged<QuickAction>? onSelected,
      VoidCallback? onEdit,
      TextScaler textScaler = TextScaler.noScaling,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: textScaler),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuickActionsGrid(
                actions: actions,
                onSelected: onSelected ?? (_) {},
                onEdit: onEdit ?? () {},
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('6 kisayolu basliklariyla cizer', (tester) async {
      _setScreen(tester, const Size(390, 844));
      await pumpGrid(tester);

      expect(find.text('Hızlı Erişim'), findsOneWidget);
      for (final action in kDefaultQuickActions) {
        expect(_card(action), findsOneWidget, reason: action.name);
        expect(
          find.descendant(of: _card(action), matching: find.text(action.title)),
          findsOneWidget,
          reason: action.name,
        );
      }
      // Katalogdaki secili olmayan bir oge izgarada gorunmez.
      expect(_card(QuickAction.campusMap), findsNothing);
    });

    testWidgets('3 sutun x 2 satir yerlesir', (tester) async {
      _setScreen(tester, const Size(390, 844));
      await pumpGrid(tester);

      final pos = [
        for (final action in kDefaultQuickActions)
          tester.getTopLeft(_card(action)),
      ];

      // Ilk satir: ayni y, soldan saga artan x.
      expect(pos[1].dy, pos[0].dy);
      expect(pos[2].dy, pos[0].dy);
      expect(pos[1].dx, greaterThan(pos[0].dx));
      expect(pos[2].dx, greaterThan(pos[1].dx));
      // Ikinci satir: ayni sutunlar, daha asagida.
      expect(pos[3].dy, greaterThan(pos[0].dy));
      expect(pos[4].dy, pos[3].dy);
      expect(pos[5].dy, pos[3].dy);
      expect(pos[3].dx, pos[0].dx);
      expect(pos[4].dx, pos[1].dx);
      expect(pos[5].dx, pos[2].dx);
    });

    testWidgets('karta dokunmak dogru kisayolla onSelected cagirir', (
      tester,
    ) async {
      _setScreen(tester, const Size(390, 844));
      final selected = <QuickAction>[];
      await pumpGrid(tester, onSelected: selected.add);

      await tester.tap(_card(QuickAction.chatbot));
      await tester.tap(_card(QuickAction.obs));

      expect(selected, [QuickAction.chatbot, QuickAction.obs]);
    });

    testWidgets('Duzenle onEdit cagirir', (tester) async {
      _setScreen(tester, const Size(390, 844));
      var edits = 0;
      await pumpGrid(tester, onEdit: () => edits++);

      await tester.tap(find.text('Düzenle'));

      expect(edits, 1);
    });

    testWidgets('verilen sirayi ve ozellestirilmis secimi cizer', (
      tester,
    ) async {
      _setScreen(tester, const Size(390, 844));
      final custom = [
        QuickAction.campusMap,
        QuickAction.lostFound,
        QuickAction.campusPhotos,
        QuickAction.emergencyContacts,
        QuickAction.obs,
        QuickAction.mediko,
      ];
      await pumpGrid(tester, actions: custom);

      for (final action in custom) {
        expect(_card(action), findsOneWidget, reason: action.name);
      }
      expect(_card(QuickAction.chatbot), findsNothing);
      expect(
        tester.getTopLeft(_card(QuickAction.campusMap)).dx,
        lessThan(tester.getTopLeft(_card(QuickAction.lostFound)).dx),
      );
    });

    testWidgets('dar ekran ve buyuk yazida tasma olmaz', (tester) async {
      _setScreen(tester, const Size(320, 640));
      await pumpGrid(tester, textScaler: const TextScaler.linear(1.3));

      expect(tester.takeException(), isNull);
      for (final action in kDefaultQuickActions) {
        expect(_card(action), findsOneWidget, reason: action.name);
      }
    });
  });

  group('showQuickActionsEditSheet', () {
    List<QuickAction>? result;
    var resultReceived = false;

    Future<void> openSheet(
      WidgetTester tester, {
      List<QuickAction> current = kDefaultQuickActions,
    }) async {
      result = null;
      resultReceived = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    result = await showQuickActionsEditSheet(context, current);
                    resultReceived = true;
                  },
                  child: const Text('Aç'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Aç'));
      await tester.pumpAndSettle();
    }

    bool addEnabled(WidgetTester tester, QuickAction action) =>
        tester.widget<IconButton>(_addButton(action)).onPressed != null;

    testWidgets('secili ve eklenebilir ogeleri listeler', (tester) async {
      _setScreen(tester, const Size(390, 1000));
      await openSheet(tester);

      expect(find.text('Hızlı Erişimi Düzenle'), findsOneWidget);
      expect(find.text('Seçili (6/6)'), findsOneWidget);
      for (final action in kDefaultQuickActions) {
        expect(_selectedRow(action), findsOneWidget, reason: action.name);
        expect(_addButton(action), findsNothing, reason: action.name);
      }
      for (final action in QuickAction.values.skip(kQuickActionSlotCount)) {
        expect(_selectedRow(action), findsNothing, reason: action.name);
        expect(_addButton(action), findsOneWidget, reason: action.name);
        expect(find.text(action.title), findsOneWidget, reason: action.name);
      }
    });

    testWidgets('6/6 iken Kaydet aktif, ekle butonlari pasif', (tester) async {
      _setScreen(tester, const Size(390, 1000));
      await openSheet(tester);

      expect(tester.widget<FilledButton>(_saveButton).onPressed, isNotNull);
      for (final action in QuickAction.values.skip(kQuickActionSlotCount)) {
        expect(addEnabled(tester, action), isFalse, reason: action.name);
      }
    });

    testWidgets('oge cikarinca Kaydet pasiflesir ve oge eklenebilire gecer', (
      tester,
    ) async {
      _setScreen(tester, const Size(390, 1000));
      await openSheet(tester);

      await tester.tap(_removeButton(QuickAction.obs));
      await tester.pumpAndSettle();

      expect(find.text('Seçili (5/6)'), findsOneWidget);
      expect(_selectedRow(QuickAction.obs), findsNothing);
      expect(_addButton(QuickAction.obs), findsOneWidget);
      expect(tester.widget<FilledButton>(_saveButton).onPressed, isNull);
      expect(find.text('6 kısayol seçmelisin'), findsOneWidget);
      expect(addEnabled(tester, QuickAction.campusMap), isTrue);
    });

    testWidgets('cikarip baska oge ekleyince Kaydet secimi dondurur', (
      tester,
    ) async {
      _setScreen(tester, const Size(390, 1000));
      await openSheet(tester);

      await tester.tap(_removeButton(QuickAction.obs));
      await tester.pumpAndSettle();
      await tester.tap(_addButton(QuickAction.campusMap));
      await tester.pumpAndSettle();

      expect(find.text('Seçili (6/6)'), findsOneWidget);
      expect(tester.widget<FilledButton>(_saveButton).onPressed, isNotNull);

      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(resultReceived, isTrue);
      expect(result, [
        QuickAction.campusCard,
        QuickAction.academicCalendar,
        QuickAction.campusSecurity,
        QuickAction.chatbot,
        QuickAction.mediko,
        QuickAction.campusMap,
      ]);
      expect(find.text('Hızlı Erişimi Düzenle'), findsNothing);
    });

    testWidgets('surukleyerek siralama degisir', (tester) async {
      _setScreen(tester, const Size(390, 1000));
      await openSheet(tester);

      // ReorderableListView kaydirmayi kare kare izler; tester.drag tek hamlede
      // tasidigi icin yeni sirayi hesaplatmaz. Gercek parmak gibi adim adim,
      // her adimdan sonra bir kare cizdirerek surukle.
      final rowHeight = tester.getSize(_selectedRow(QuickAction.obs)).height;
      final gesture = await tester.startGesture(
        tester.getCenter(_dragHandle(QuickAction.obs)),
      );
      await tester.pump();
      for (var step = 0; step < 6; step++) {
        await gesture.moveBy(Offset(0, rowHeight * 1.2 / 6));
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.tap(_saveButton);
      await tester.pumpAndSettle();

      expect(result, [
        QuickAction.campusCard,
        QuickAction.obs,
        QuickAction.academicCalendar,
        QuickAction.campusSecurity,
        QuickAction.chatbot,
        QuickAction.mediko,
      ]);
    });

    testWidgets('Varsayilana don taslagi varsayilan izgaraya geri alir', (
      tester,
    ) async {
      _setScreen(tester, const Size(390, 1000));
      await openSheet(
        tester,
        current: const [
          QuickAction.campusMap,
          QuickAction.lostFound,
          QuickAction.campusPhotos,
          QuickAction.emergencyContacts,
          QuickAction.obs,
          QuickAction.mediko,
        ],
      );
      expect(_selectedRow(QuickAction.campusMap), findsOneWidget);

      await tester.tap(find.text('Varsayılana dön'));
      await tester.pumpAndSettle();

      expect(find.text('Seçili (6/6)'), findsOneWidget);
      for (final action in kDefaultQuickActions) {
        expect(_selectedRow(action), findsOneWidget, reason: action.name);
      }
      expect(_selectedRow(QuickAction.campusMap), findsNothing);

      await tester.tap(_saveButton);
      await tester.pumpAndSettle();
      expect(result, kDefaultQuickActions);
    });

    testWidgets('kaydetmeden kapatmak null doner', (tester) async {
      _setScreen(tester, const Size(390, 1000));
      await openSheet(tester);

      await tester.tap(_removeButton(QuickAction.obs));
      await tester.pumpAndSettle();
      // Sheet disindaki karartma alanina dokunarak kapat.
      await tester.tapAt(const Offset(195, 8));
      await tester.pumpAndSettle();

      expect(resultReceived, isTrue);
      expect(result, isNull);
    });

    testWidgets('kucuk ekranda tasmaz ve Kaydet gorunur kalir', (tester) async {
      _setScreen(tester, const Size(360, 560));
      await openSheet(tester);

      expect(tester.takeException(), isNull);
      expect(_saveButton, findsOneWidget);
      final saveRect = tester.getRect(_saveButton);
      expect(saveRect.bottom, lessThanOrEqualTo(560));
      expect(saveRect.top, greaterThanOrEqualTo(0));
    });
  });
}
