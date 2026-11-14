import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mjux/mjux.dart';

void main() {
  testWidgets('required input blocks save and later edits stay unsaved', (
    tester,
  ) async {
    final name = FieldKey();
    final pending = Completer<SaveResult>();
    final requests = <SaveRequested>[];
    final surface = const Utility().open(
      FormEditor1(
        title: 'Details',
        fields: [TextFieldSpec(key: name, label: 'Name', isRequired: true)],
      ),
      initialValues: {name: 'Original'},
      onSave: (request) {
        requests.add(request);
        return pending.future;
      },
    );
    addTearDown(surface.dispose);
    await tester.pumpWidget(_host(surface));

    final input = find.byType(EditableText);
    await tester.enterText(input, '  ');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
    expect(requests, isEmpty);

    await tester.enterText(input, 'First edit');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Saving…'), findsOneWidget);

    await tester.enterText(input, 'Second edit');
    await tester.pump();
    expect(requests.single.values[name], 'First edit');
    pending.complete(const SaveSucceeded());
    await tester.pump();

    expect(find.text('Saved. New edits are unsaved.'), findsOneWidget);
    expect(tester.widget<EditableText>(input).controller.text, 'Second edit');
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('a pending host save can complete after disposal', (
    tester,
  ) async {
    final name = FieldKey();
    final pending = Completer<SaveResult>();
    final surface = const Utility().open(
      FormEditor1(
        title: 'Details',
        fields: [TextFieldSpec(key: name, label: 'Name')],
      ),
      initialValues: {name: 'Original'},
      onSave: (_) => pending.future,
    );
    addTearDown(surface.dispose);
    await tester.pumpWidget(_host(surface));
    await tester.enterText(find.byType(EditableText), 'Edited');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Saving…'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    surface.dispose();
    pending.complete(const SaveSucceeded());
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

Widget _host(Surface surface) => MaterialApp(
  home: Scaffold(body: SurfaceView(surface: surface)),
);
