import 'package:akdenizcep/features/student_events/pages/components/event_location_title_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('konum başlığı alanı açıldığında otomatik odaklanmaz', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventLocationTitleField(
            controller: TextEditingController(),
            onChanged: (_) {},
            onSubmitted: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.autofocus, false);
    expect(editable.focusNode.hasFocus, false);
  });
}
