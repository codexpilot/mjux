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
      final original = _rows(
        jv: 42,
        jid: 7,
        encoding: 1010,
        schema: {'id': DataType.int64.id, 'name': DataType.text.id},
        data: [
          [1, 'Alice'],
          [2, 'Bob'],
        ],
      );
      final binding = JsonCFormBinding(
        form: form,
        jv: original.jv,
        jid: original.jid,
        schema: original.schema,
        data: original.data,
        encoding: original.encoding,
        rowIndex: 1,
        columns: {name: 'name'},
      );

      expect(binding.initialValues, {name: 'Bob'});
      final result = binding.toJsonC(SaveRequested({name: 'Robert'}));
      expect(result.jv, 42);
      expect(result.jid, 7);
      expect(result.encoding, 1010);
      expect(result.schema, original.schema);
      expect(result.data, [
        [1, 'Alice'],
        [2, 'Robert'],
      ]);
      expect(original.data, [
        [1, 'Alice'],
        [2, 'Bob'],
      ]);
      expect(_decode(result), result.data);
    });

    test('validates schema, row, field bindings, and data types', () {
      final name = FieldKey();
      final other = FieldKey();
      final form = FormEditor1(
        title: 'Contact',
        fields: [TextFieldSpec(key: name, label: 'Name')],
      );
      JsonCFormBinding bind(
        _Rows jsonc,
        int row,
        Map<FieldKey, String> columns,
      ) => JsonCFormBinding(
        form: form,
        jv: jsonc.jv,
        jid: jsonc.jid,
        schema: jsonc.schema,
        data: jsonc.data,
        encoding: jsonc.encoding,
        rowIndex: row,
        columns: columns,
      );
      final valid = _rows(
        jv: 1,
        jid: 2,
        schema: {'name': DataType.text.id},
        data: [
          ['Alice'],
        ],
      );

      expect(
        () => bind(
          _rows(
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
          _rows(jv: 1, jid: 2, schema: {'name': DataType.text.id}),
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
          _rows(
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
          _rows(jv: 1, jid: 2, schema: {'name': DataType.text.id}, data: [[]]),
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
        encoding: 1000,
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
      final source = _rows(
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
        jv: source.jv,
        jid: source.jid,
        schema: source.schema,
        data: source.data,
        encoding: source.encoding,
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

    test('keeps decimal strings exact in JX string mode', () {
      final amount = FieldKey();
      final binding = JsonCFormBinding(
        form: FormEditor1(
          title: 'Amount',
          fields: [TextFieldSpec(key: amount, label: 'Amount')],
        ),
        jv: 1,
        jid: 2,
        encoding: 1000,
        schema: {'amount': DataType.numeric.id},
        data: [
          ['12345678901234567890.123456789'],
        ],
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
        jv: 1,
        jid: 2,
        schema: {'details': DataType.jsonb.id},
        data: [
          [sourceDetails],
        ],
        encoding: 1000,
        rowIndex: 0,
        columns: {details: 'details'},
      );
      (sourceDetails['items'] as List).clear();
      final saved = binding.toJsonC(SaveRequested(binding.initialValues));
      final object = saved.data[0][0] as Map<String, dynamic>;
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
        jv: 1,
        jid: 2,
        encoding: 1100,
        schema: {'id': DataType.int64.id},
        data: [
          ['0'],
        ],
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
        jv: 1,
        jid: 2,
        encoding: 1110,
        schema: {'id': DataType.int64.id},
        data: [
          [0],
        ],
        rowIndex: 0,
        columns: {id: 'id'},
      );
      for (final text in ['-9223372036854775808', '9223372036854775807']) {
        final saved = binding.toJsonC(SaveRequested({id: text}));
        expect(saved.data[0][0], int.parse(text));
        expect(_decode(saved), saved.data);
      }
    }, skip: const bool.fromEnvironment('dart.library.js_interop'));

    test('enforces parameterized numeric precision and scale', () {
      final amount = FieldKey();
      final binding = JsonCFormBinding(
        form: FormEditor1(
          title: 'Amount',
          fields: [TextFieldSpec(key: amount, label: 'Amount')],
        ),
        jv: 1,
        jid: 2,
        encoding: 1000,
        schema: {
          'amount': DataTypeRegistry.encodeNumeric(precision: 5, scale: 2),
        },
        data: [
          ['0.00'],
        ],
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
      final schema = {
        'id': DataType.int64.id,
        'name': DataType.text.id,
        'other': DataType.int64.id,
      };
      const encoding = 1000;
      final source = _rows(
        jv: 1,
        jid: 2,
        encoding: encoding,
        schema: schema,
        data: JxCodec.decodeFromJsonString(
          encoding: encoding,
          schema: _jxSchema(schema),
          jsonString: '{"data":[["9223372036854775807","Original","-9223372036854775808"],["42","Other row","43"]]}',
        ),
      );
      expect(source.data[0][0], BigInt.parse('9223372036854775807'));
      final binding = JsonCFormBinding(
        form: FormEditor1(
          title: 'Record',
          fields: [
            TextFieldSpec(key: id, label: 'ID'),
            TextFieldSpec(key: name, label: 'Name'),
          ],
        ),
        jv: source.jv,
        jid: source.jid,
        schema: source.schema,
        data: source.data,
        encoding: source.encoding,
        rowIndex: 0,
        columns: {id: 'id', name: 'name'},
      );
      expect(binding.initialValues[id], '9223372036854775807');
      final updated = binding.toJsonC(
        SaveRequested({id: '-9223372036854775808', name: 'Edited'}),
      );
      expect(updated.data[0][0], BigInt.parse('-9223372036854775808'));
      expect(updated.data[0][2], BigInt.parse('-9223372036854775808'));
      expect(updated.data[1], [BigInt.from(42), 'Other row', BigInt.from(43)]);
      expect(source.data[0][1], 'Original');
      expect(_decode(updated), updated.data);
      expect(_encode(updated).data[0], [
        '-9223372036854775808',
        'Edited',
        '-9223372036854775808',
      ]);
    });

    test('accepts constructed BigInt cells for each INT64 string mode', () {
      for (final mode in [1000, 1100, 8000, 8100]) {
        final id = FieldKey();
        final source = _rows(
          jv: 1,
          jid: 2,
          encoding: mode,
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
          jv: source.jv,
          jid: source.jid,
          schema: source.schema,
          data: source.data,
          encoding: source.encoding,
          rowIndex: 0,
          columns: {id: 'id'},
        );
        expect(binding.initialValues[id], '9223372036854775807');
        final unchanged = binding.toJsonC(SaveRequested(binding.initialValues));
        expect(unchanged.data, source.data);
        final edited = binding.toJsonC(SaveRequested({id: '8'}));
        expect(_decode(edited), [
          [BigInt.from(8), BigInt.from(7)],
        ]);
      }
    });

    test('normalizes INT64 for display for constructed string cells', () {
      final id = FieldKey();
      final binding = JsonCFormBinding(
        form: FormEditor1(
          title: 'ID',
          fields: [TextFieldSpec(key: id, label: 'ID')],
        ),
        jv: 1,
        jid: 2,
        encoding: 1000,
        schema: {'id': DataType.int64.id},
        data: [
          ['00042'],
        ],
        rowIndex: 0,
        columns: {id: 'id'},
      );
      expect(binding.initialValues[id], '42');
      final unchanged = binding.toJsonC(SaveRequested(binding.initialValues));
      expect(unchanged.data, [
        ['00042'],
      ]);
      expect(_decode(unchanged), [
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
        jv: 1,
        jid: 2,
        encoding: 1000,
        schema: {'amount': DataType.numeric.id, 'name': DataType.text.id},
        data: [
          ['001.2300', 'Original'],
        ],
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
        jv: 1,
        jid: 2,
        schema: {'name': DataType.text.id},
        data: [
          ['Alice'],
        ],
        encoding: 1000,
        rowIndex: 0,
        columns: {name: 'name'},
      );
      _Rows? saved;
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

typedef _Rows = ({
  Map<String, int> schema,
  List<List<dynamic>> data,
  int encoding,
  int? jv,
  int? jid,
});

_Rows _rows({
  Map<String, int> schema = const {},
  List<List<dynamic>> data = const [],
  int encoding = 1000,
  int? jv,
  int? jid,
}) => (schema: schema, data: data, encoding: encoding, jv: jv, jid: jid);

JxSchema _jxSchema(Map<String, int> schema) => JxSchema([
  for (final (index, column) in schema.entries.indexed)
    JxField(
      i: index + 1,
      c: column.key,
      n: column.key,
      typeId: column.value,
      typeName: column.value.toString(),
    ),
]);

JxBody _encode(_Rows rows) => JxCodec.encode(
  rows: rows.data,
  encoding: rows.encoding,
  schema: _jxSchema(rows.schema),
);

List<List<dynamic>> _decode(_Rows rows) => JxCodec.decodeFromJsonString(
  encoding: rows.encoding,
  schema: _jxSchema(rows.schema),
  jsonString: _encode(rows).encode(),
);
