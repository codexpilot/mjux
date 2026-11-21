import 'package:flutter_test/flutter_test.dart';
import 'package:jcore/jcore.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mjux/mjux.dart';

void main() {
  group('JsonCFormBinding', () {
    test('edits a mapped row while retaining metadata and other data', () {
      final name = FieldKey();
      final form = FormEditor1(
        title: 'Contact',
        fields: [TextFieldSpec(key: name, label: 'Name')],
      );
      final original = JsonC(
        jv: 42,
        jid: 7,
        jnf: 3,
        schema: {'id': DataType.int64.id, 'name': DataType.text.id},
        data: [
          [1, 'Alice'],
          [2, 'Bob'],
        ],
      );
      final binding = JsonCFormBinding(
        form: form,
        jsonc: original,
        rowIndex: 1,
        columns: {name: 'name'},
      );

      expect(binding.initialValues, {name: 'Bob'});
      final result = binding.toJsonC(SaveRequested({name: 'Robert'}));
      expect(result.jv, 42);
      expect(result.jid, 7);
      expect(result.jnf, 3);
      expect(result.schema, original.schema);
      expect(result.data, [
        [1, 'Alice'],
        [2, 'Robert'],
      ]);
      expect(original.data, [
        [1, 'Alice'],
        [2, 'Bob'],
      ]);
      expect(JsonC.parse(result.encode()).toJson(), result.toJson());
    });

    test('validates schema, row, field bindings, and data types', () {
      final name = FieldKey();
      final other = FieldKey();
      final form = FormEditor1(
        title: 'Contact',
        fields: [TextFieldSpec(key: name, label: 'Name')],
      );
      JsonCFormBinding bind(
        JsonC jsonc,
        int row,
        Map<FieldKey, String> columns,
      ) => JsonCFormBinding(
        form: form,
        jsonc: jsonc,
        rowIndex: row,
        columns: columns,
      );
      final valid = JsonC(
        jv: 1,
        jid: 2,
        schema: {'name': DataType.text.id},
        data: [
          ['Alice'],
        ],
      );

      expect(
        () => bind(
          JsonC(
            jv: 1,
            jid: 2,
            data: [
              ['Alice'],
            ],
          ),
          0,
          {name: 'name'},
        ),
        throwsArgumentError,
      );
      expect(
        () => bind(
          JsonC(jv: 1, jid: 2, schema: {'name': DataType.text.id}),
          0,
          {name: 'name'},
        ),
        throwsArgumentError,
      );
      expect(() => bind(valid, 1, {name: 'name'}), throwsArgumentError);
      expect(() => bind(valid, -1, {name: 'name'}), throwsArgumentError);
      expect(() => bind(valid, 0, {other: 'name'}), throwsArgumentError);
      expect(() => bind(valid, 0, {name: 'missing'}), throwsArgumentError);
      expect(
        () => bind(
          JsonC(
            jv: 1,
            jid: 2,
            schema: {'name': 999999},
            data: [
              ['Alice'],
            ],
          ),
          0,
          {name: 'name'},
        ),
        throwsArgumentError,
      );
      expect(
        () => bind(
          JsonC(jv: 1, jid: 2, schema: {'name': DataType.text.id}, data: [[]]),
          0,
          {name: 'name'},
        ),
        throwsArgumentError,
      );
    });

    test('round trips typed values and preserves null and bounded text', () {
      final text = FieldKey();
      final enabled = FieldKey();
      final count = FieldKey();
      final when = FieldKey();
      final details = FieldKey();
      final fields = [text, enabled, count, when, details];
      final form = FormEditor1(
        title: 'Typed',
        fields: [
          for (final key in fields) TextFieldSpec(key: key, label: 'Value'),
        ],
      );
      final binding = JsonCFormBinding(
        form: form,
        jsonc: JsonC(
          jv: 1,
          jid: 2,
          schema: {
            'text': DataTypeRegistry.encodeText(length: 5),
            'enabled': DataType.boolean.id,
            'count': DataType.int32.id,
            'when': DataType.datetime.id,
            'details': DataType.jsonb.id,
          },
          data: [
            [
              null,
              true,
              3,
              1700000000000,
              {'x': 1},
            ],
          ],
        ),
        rowIndex: 0,
        columns: {
          text: 'text',
          enabled: 'enabled',
          count: 'count',
          when: 'when',
          details: 'details',
        },
      );
      expect(binding.initialValues[text], isNull);
      expect(binding.initialValues[enabled], 'true');
      expect(binding.initialValues[count], '3');
      expect(binding.initialValues[when], '1700000000000');
      final result = binding.toJsonC(
        SaveRequested({
          text: 'hello',
          enabled: 'false',
          count: '-9',
          when: '1700000000001',
          details: '{"x":2}',
        }),
      );
      expect(result.data, [
        [
          'hello',
          false,
          -9,
          1700000000001,
          {'x': 2},
        ],
      ]);
      expect(
        () => binding.toJsonC(
          SaveRequested({
            text: 'longer',
            enabled: 'false',
            count: '-9',
            when: '1700000000001',
            details: '{"x":2}',
          }),
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid typed edits without mutating the source', () {
      final enabled = FieldKey();
      final count = FieldKey();
      final details = FieldKey();
      final source = JsonC(
        jv: 1,
        jid: 2,
        schema: {
          'enabled': DataType.boolean.id,
          'count': DataType.int32.id,
          'details': DataType.jsonb.id,
        },
        data: [
          [
            true,
            1,
            {'ok': true},
          ],
        ],
      );
      final binding = JsonCFormBinding(
        form: FormEditor1(
          title: 'Typed',
          fields: [
            TextFieldSpec(key: enabled, label: 'Enabled'),
            TextFieldSpec(key: count, label: 'Count'),
            TextFieldSpec(key: details, label: 'Details'),
          ],
        ),
        jsonc: source,
        rowIndex: 0,
        columns: {enabled: 'enabled', count: 'count', details: 'details'},
      );
      for (final values in [
        {enabled: 'yes', count: '1', details: '{}'},
        {enabled: 'true', count: 'one', details: '{}'},
        {enabled: 'true', count: '2147483648', details: '{}'},
        {enabled: 'true', count: '1', details: '{'},
      ]) {
        expect(() => binding.toJsonC(SaveRequested(values)), throwsA(anything));
      }
      expect(source.data, [
        [
          true,
          1,
          {'ok': true},
        ],
      ]);
    });

    test('keeps decimal strings exact in precision-safe JSONC mode', () {
      final amount = FieldKey();
      final binding = JsonCFormBinding(
        form: FormEditor1(
          title: 'Amount',
          fields: [TextFieldSpec(key: amount, label: 'Amount')],
        ),
        jsonc: JsonC(
          jv: 1,
          jid: 2,
          jnf: 4,
          schema: {'amount': DataType.numeric.id},
          data: [
            ['12345678901234567890.123456789'],
          ],
        ),
        rowIndex: 0,
        columns: {amount: 'amount'},
      );
      expect(binding.initialValues[amount], '12345678901234567890.123456789');
      final result = binding.toJsonC(
        SaveRequested({amount: '999999999999999999.00001'}),
      );
      expect(result.data, [
        [Numeric.fromString('999999999999999999.00001', 5)],
      ]);
      expect(
        () => binding.toJsonC(SaveRequested({amount: 'not a number'})),
        throwsA(anything),
      );
    });

    test('snapshots nested JSON independently and returns immutable data', () {
      final details = FieldKey();
      final sourceDetails = <String, dynamic>{
        'items': <dynamic>[
          <String, dynamic>{'value': 'original'},
        ],
      };
      final binding = JsonCFormBinding(
        form: FormEditor1(
          title: 'Details',
          fields: [TextFieldSpec(key: details, label: 'Details')],
        ),
        jsonc: JsonC(
          jv: 1,
          jid: 2,
          schema: {'details': DataType.jsonb.id},
          data: [
            [sourceDetails],
          ],
        ),
        rowIndex: 0,
        columns: {details: 'details'},
      );
      (sourceDetails['items'] as List).clear();
      final saved = binding.toJsonC(SaveRequested(binding.initialValues));
      final object = saved.data![0][0] as Map<String, dynamic>;
      final items = object['items'] as List;
      expect(items, [
        {'value': 'original'},
      ]);
      expect(() => items.clear(), throwsUnsupportedError);
      expect(
        () => (items[0] as Map)['value'] = 'changed',
        throwsUnsupportedError,
      );
    });

    test('handles full signed int64 range in string mode', () {
      final value = FieldKey();
      final binding = JsonCFormBinding(
        form: FormEditor1(
          title: 'ID',
          fields: [TextFieldSpec(key: value, label: 'ID')],
        ),
        jsonc: JsonC(
          jv: 1,
          jid: 2,
          jnf: 3,
          schema: {'id': DataType.int64.id},
          data: [
            ['0'],
          ],
        ),
        rowIndex: 0,
        columns: {value: 'id'},
      );
      for (final valid in ['-9223372036854775808', '9223372036854775807']) {
        expect(binding.toJsonC(SaveRequested({value: valid})).data, [
          [BigInt.parse(valid)],
        ]);
      }
      for (final invalid in ['-9223372036854775809', '9223372036854775808']) {
        expect(
          () => binding.toJsonC(SaveRequested({value: invalid})),
          throwsArgumentError,
        );
      }
    });

    test('round trips native raw-mode int64 at signed limits', () {
      final id = FieldKey();
      final binding = JsonCFormBinding(
        form: FormEditor1(
          title: 'ID',
          fields: [TextFieldSpec(key: id, label: 'ID')],
        ),
        jsonc: JsonC(
          jv: 1,
          jid: 2,
          jnf: 2,
          schema: {'id': DataType.int64.id},
          data: [
            [0],
          ],
        ),
        rowIndex: 0,
        columns: {id: 'id'},
      );
      for (final text in ['-9223372036854775808', '9223372036854775807']) {
        final saved = binding.toJsonC(SaveRequested({id: text}));
        expect(saved.data![0][0], int.parse(text));
        expect(JsonC.parse(saved.encode()).data, saved.data);
      }
    }, skip: const bool.fromEnvironment('dart.library.js_interop'));

    test('enforces parameterized numeric precision and scale', () {
      final amount = FieldKey();
      final binding = JsonCFormBinding(
        form: FormEditor1(
          title: 'Amount',
          fields: [TextFieldSpec(key: amount, label: 'Amount')],
        ),
        jsonc: JsonC(
          jv: 1,
          jid: 2,
          jnf: 4,
          schema: {
            'amount': DataTypeRegistry.encodeNumeric(precision: 5, scale: 2),
          },
          data: [
            ['0.00'],
          ],
        ),
        rowIndex: 0,
        columns: {amount: 'amount'},
      );
      for (final valid in ['999.99', '-0.01', '00012.30', '1.2300', '1e2']) {
        final decimal = valid == '1e2' ? '100' : valid;
        expect(binding.toJsonC(SaveRequested({amount: valid})).data, [
          [Numeric.fromString(decimal, 2)],
        ]);
      }
      for (final invalid in ['1000.00', '1.234', 'not-a-number']) {
        expect(
          () => binding.toJsonC(SaveRequested({amount: invalid})),
          throwsArgumentError,
        );
      }
    });

    test('edits parsed INT64 values and retains other BigInt cells', () {
      final id = FieldKey();
      final name = FieldKey();
      final source = JsonC.fromJson({
        'jv': 1,
        'jid': 2,
        'jnf': 5,
        'schema': {
          'id': DataType.int64.id,
          'name': DataType.text.id,
          'other': DataType.int64.id,
        },
        'data': [
          ['9223372036854775807', 'Original', '-9223372036854775808'],
          ['42', 'Other row', '43'],
        ],
      });
      expect(source.data![0][0], BigInt.parse('9223372036854775807'));
      final binding = JsonCFormBinding(
        form: FormEditor1(
          title: 'Record',
          fields: [
            TextFieldSpec(key: id, label: 'ID'),
            TextFieldSpec(key: name, label: 'Name'),
          ],
        ),
        jsonc: source,
        rowIndex: 0,
        columns: {id: 'id', name: 'name'},
      );
      expect(binding.initialValues[id], '9223372036854775807');
      final updated = binding.toJsonC(
        SaveRequested({id: '-9223372036854775808', name: 'Edited'}),
      );
      expect(updated.data![0][0], BigInt.parse('-9223372036854775808'));
      expect(updated.data![0][2], BigInt.parse('-9223372036854775808'));
      expect(updated.data![1], [BigInt.from(42), 'Other row', BigInt.from(43)]);
      expect(source.data![0][1], 'Original');
      final roundTrip = JsonC.parse(updated.encode());
      expect(roundTrip.data, updated.data);
      expect((updated.toJson()['data'] as List)[0], [
        '-9223372036854775808',
        'Edited',
        '-9223372036854775808',
      ]);
    });

    test('accepts constructed BigInt cells for each INT64 string mode', () {
      for (final mode in [0, 3, 5]) {
        final id = FieldKey();
        final source = JsonC(
          jv: 1,
          jid: 2,
          jnf: mode,
          schema: {'id': DataType.int64.id, 'other': DataType.int64.id},
          data: [
            [BigInt.parse('9223372036854775807'), BigInt.from(7)],
          ],
        );
        final binding = JsonCFormBinding(
          form: FormEditor1(
            title: 'ID',
            fields: [TextFieldSpec(key: id, label: 'ID')],
          ),
          jsonc: source,
          rowIndex: 0,
          columns: {id: 'id'},
        );
        expect(binding.initialValues[id], '9223372036854775807');
        final unchanged = binding.toJsonC(SaveRequested(binding.initialValues));
        expect(unchanged.data, source.data);
        final edited = binding.toJsonC(SaveRequested({id: '8'}));
        expect(JsonC.parse(edited.encode()).data, [
          [BigInt.from(8), BigInt.from(7)],
        ]);
      }
    });

    test('uses jcore INT64 normalization for constructed string cells', () {
      final id = FieldKey();
      final binding = JsonCFormBinding(
        form: FormEditor1(
          title: 'ID',
          fields: [TextFieldSpec(key: id, label: 'ID')],
        ),
        jsonc: JsonC(
          jv: 1,
          jid: 2,
          jnf: 3,
          schema: {'id': DataType.int64.id},
          data: [
            ['00042'],
          ],
        ),
        rowIndex: 0,
        columns: {id: 'id'},
      );
      expect(binding.initialValues[id], '42');
      final unchanged = binding.toJsonC(SaveRequested(binding.initialValues));
      expect(unchanged.data, [
        ['00042'],
      ]);
      expect(JsonC.parse(unchanged.encode()).data, [
        [BigInt.from(42)],
      ]);
    });

    test('retains an unchanged mapped value representation across saves', () {
      final amount = FieldKey();
      final name = FieldKey();
      final binding = JsonCFormBinding(
        form: FormEditor1(
          title: 'Item',
          fields: [
            TextFieldSpec(key: amount, label: 'Amount'),
            TextFieldSpec(key: name, label: 'Name'),
          ],
        ),
        jsonc: JsonC(
          jv: 1,
          jid: 2,
          jnf: 4,
          schema: {'amount': DataType.numeric.id, 'name': DataType.text.id},
          data: [
            ['001.2300', 'Original'],
          ],
        ),
        rowIndex: 0,
        columns: {amount: 'amount', name: 'name'},
      );
      final first = binding.toJsonC(
        SaveRequested({amount: '001.2300', name: 'First'}),
      );
      final second = binding.toJsonC(
        SaveRequested({amount: '001.2300', name: 'Second'}),
      );
      expect(first.data, [
        ['001.2300', 'First'],
      ]);
      expect(second.data, [
        ['001.2300', 'Second'],
      ]);
    });

    testWidgets('initializes and saves a form through the binding', (
      tester,
    ) async {
      final name = FieldKey();
      final form = FormEditor1(
        title: 'Contact',
        fields: [TextFieldSpec(key: name, label: 'Name')],
      );
      final binding = JsonCFormBinding(
        form: form,
        jsonc: JsonC(
          jv: 1,
          jid: 2,
          schema: {'name': DataType.text.id},
          data: [
            ['Alice'],
          ],
        ),
        rowIndex: 0,
        columns: {name: 'name'},
      );
      JsonC? saved;
      final surface = const Utility().open(
        form,
        initialValues: binding.initialValues,
        onSave: (request) async {
          saved = binding.toJsonC(request);
          return const SaveSucceeded();
        },
      );
      addTearDown(surface.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: SurfaceView(surface: surface)),
        ),
      );
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        'Alice',
      );
      await tester.enterText(find.byType(EditableText), 'Bob');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(saved!.data, [
        ['Bob'],
      ]);
    });
  });
}
