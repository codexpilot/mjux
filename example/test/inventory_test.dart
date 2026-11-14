import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mjux/mjux.dart';
import 'package:mjux_example/main.dart';

void main() {
  testWidgets('drafts are isolated and saves use the host callback', (
    tester,
  ) async {
    await tester.pumpWidget(const InventoryApp());

    final surfaces = find.byType(SurfaceView);
    expect(surfaces, findsNWidgets(2));
    final firstInput = find.descendant(
      of: surfaces.at(0),
      matching: find.byType(EditableText),
    );
    final secondInput = find.descendant(
      of: surfaces.at(1),
      matching: find.byType(EditableText),
    );
    final firstSave = find.descendant(
      of: surfaces.at(0),
      matching: find.text('Save'),
    );

    expect(tester.widget<EditableText>(firstInput).controller.text, 'Basil');
    expect(
      tester.widget<EditableText>(secondInput).controller.text,
      'Calendula',
    );
    await tester.enterText(firstInput, 'Mint');
    await tester.pump();
    expect(
      tester.widget<EditableText>(secondInput).controller.text,
      'Calendula',
    );
    expect(find.text('Saved: Basil · Herbs'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: surfaces.at(0),
        matching: find.byType(DropdownButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vegetables').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(firstSave);
    await tester.tap(firstSave);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Saved: Mint · Vegetables'), findsOneWidget);
    expect(find.text('Saved: Calendula · Flowers'), findsOneWidget);

    await tester.enterText(firstInput, 'calendula');
    await tester.pump();
    await tester.tap(firstSave);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('A plant with that name already exists.'), findsOneWidget);
    expect(find.text('Saved: Mint · Vegetables'), findsOneWidget);
    expect(
      tester.widget<EditableText>(secondInput).controller.text,
      'Calendula',
    );
  });
}
