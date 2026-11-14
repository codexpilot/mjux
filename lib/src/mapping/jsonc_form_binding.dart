import 'dart:convert';

import 'package:jcore/jcore.dart';

import '../catalog/form_editor_1.dart';

/// Binds the fields of a form to columns in one row of a full jcore JSONC.
///
/// The binding snapshots its input. Use [initialValues] when opening a surface,
/// then pass its save request to [toJsonC]. Unbound columns and other rows are
/// preserved. Values are displayed as text; datetime and time use the integer
/// representations defined by jcore, not localized dates or times.
final class JsonCFormBinding {
  factory JsonCFormBinding({
    required FormEditor1 form,
    required JsonC jsonc,
    required int rowIndex,
    required Map<FieldKey, String> columns,
  }) {
    final schema = jsonc.schema;
    final data = jsonc.data;
    if (jsonc.jv < 0 ||
        jsonc.jid < 0 ||
        jsonc.encoding < 0 ||
        jsonc.encoding > 5 ||
        schema == null ||
        data == null) {
      throw ArgumentError('A full JSONC with valid metadata is required.');
    }
    final schemaErrors = JConverter.validateSchema(schema);
    if (schemaErrors.isNotEmpty) throw ArgumentError(schemaErrors.join('; '));
    if (data.any((row) => row.length != schema.length)) {
      throw ArgumentError('Every JSONC row must match the schema width.');
    }
    if (rowIndex < 0 || rowIndex >= data.length) {
      throw ArgumentError.value(rowIndex, 'rowIndex', 'Row does not exist.');
    }
    final fieldKeys = form.fields.map((field) => field.key).toSet();
    if (columns.length != fieldKeys.length ||
        columns.keys.any((key) => !fieldKeys.contains(key)) ||
        columns.values.toSet().length != columns.length ||
        columns.values.any((name) => !schema.containsKey(name))) {
      throw ArgumentError(
        'Each form field must map to a unique schema column.',
      );
    }
    final frozen = JsonC(
      jv: jsonc.jv,
      jid: jsonc.jid,
      jnf: jsonc.jnf,
      schema: Map<String, int>.unmodifiable(schema),
      data: List<List<dynamic>>.unmodifiable(
        data.map((row) => _freezeRow(row, schema.values.toList())),
      ),
    );
    // JConverter uses jcore's schema order to map row cells to column names.
    final row = JConverter.toMaps(frozen)[rowIndex];
    final initial = <FieldKey, String?>{};
    for (final field in form.fields) {
      final column = columns[field.key]!;
      final display = _displayValue(row[column], schema[column]!, frozen);
      _validateChoice(field, display);
      initial[field.key] = display;
    }
    return JsonCFormBinding._(
      form,
      frozen,
      rowIndex,
      Map.unmodifiable(columns),
      Map.unmodifiable(initial),
    );
  }

  JsonCFormBinding._(
    this._form,
    this._jsonc,
    this._rowIndex,
    this._columns,
    this.initialValues,
  );

  final FormEditor1 _form;
  final JsonC _jsonc;
  final int _rowIndex;
  final Map<FieldKey, String> _columns;

  /// Values keyed by the same [FieldKey] objects used in the form.
  final Map<FieldKey, String?> initialValues;

  /// Returns a new immutable JSONC snapshot containing the submitted row.
  ///
  /// The original cell is retained when its displayed value is unchanged.
  /// Invalid or unrepresentable edited values throw [ArgumentError].
  JsonC toJsonC(SaveRequested request) {
    if (request.values.length != _columns.length ||
        request.values.keys.any((key) => !_columns.containsKey(key))) {
      throw ArgumentError('Save values must contain exactly the bound fields.');
    }
    final names = _jsonc.columnNames;
    final rows = _jsonc.data!.map((row) => List<dynamic>.of(row)).toList();
    for (final field in _form.fields) {
      final value = request.values[field.key];
      _validateChoice(field, value);
      if (value == initialValues[field.key]) continue;
      final name = _columns[field.key]!;
      rows[_rowIndex][names.indexOf(name)] = _parseValue(
        value,
        _jsonc.schema![name]!,
        _jsonc,
      );
    }
    return JsonC(
      jv: _jsonc.jv,
      jid: _jsonc.jid,
      jnf: _jsonc.jnf,
      schema: _jsonc.schema,
      data: List<List<dynamic>>.unmodifiable(
        rows.map((row) => _freezeRow(row, _jsonc.schema!.values.toList())),
      ),
    );
  }
}

void _validateChoice(FieldSpec field, String? value) {
  if (field is ChoiceFieldSpec &&
      value != null &&
      !field.options.contains(value)) {
    throw ArgumentError('Invalid choice for ${field.label}.');
  }
}

String? _displayValue(dynamic value, int type, JsonC jsonc) {
  if (value == null) return null;
  if (isValidTextType(type) ||
      type == JDataType.uuid.id ||
      type == JDataType.text0z.id) {
    if (value is! String) {
      throw ArgumentError('Expected a string for type $type.');
    }
    _checkTextLength(value, type);
    return value;
  }
  if (type == JDataType.boolean.id) {
    if (value is! bool) throw ArgumentError('Expected a boolean.');
    return value.toString();
  }
  if (_isInteger(type)) {
    final stringMode = type == JDataType.int64.id && jsonc.useBigIntStrings;
    if (stringMode ? value is! BigInt : value is! int) {
      throw ArgumentError('Unexpected integer representation for type $type.');
    }
    final text = value.toString();
    _parseInteger(text, type, stringMode);
    return text;
  }
  if (isValidNumericType(type)) {
    if (jsonc.useNumericStrings ? value is! String : value is! num) {
      throw ArgumentError('Unexpected numeric representation.');
    }
    final text = value.toString();
    _checkDecimal(value as Object, type);
    if (value is num && !value.isFinite) {
      throw ArgumentError('Non-finite numeric value.');
    }
    return text;
  }
  if (type == JDataType.jsonb.id) return jsonEncode(value);
  throw ArgumentError('Unsupported jcore data type $type.');
}

dynamic _parseValue(String? value, int type, JsonC jsonc) {
  if (value == null) return null;
  if (isValidTextType(type) ||
      type == JDataType.uuid.id ||
      type == JDataType.text0z.id) {
    _checkTextLength(value, type);
    return value;
  }
  if (type == JDataType.boolean.id) {
    if (value == 'true') return true;
    if (value == 'false') return false;
    throw ArgumentError('Boolean must be true or false.');
  }
  if (_isInteger(type)) {
    final stringMode = type == JDataType.int64.id && jsonc.useBigIntStrings;
    final integer = _parseInteger(value, type, stringMode);
    return stringMode ? integer : integer.toInt();
  }
  if (isValidNumericType(type)) {
    _checkDecimal(value, type);
    if (jsonc.useNumericStrings) return value;
    // Only safe integers have an exact, portable representation in raw mode.
    if (!RegExp(r'^[+-]?\d+$').hasMatch(value)) {
      throw ArgumentError('Edited decimals require a numeric-string jnf mode.');
    }
    final integer = BigInt.parse(value);
    if (integer.abs() > BigInt.from(9007199254740991)) {
      throw ArgumentError(
        'Raw numeric value exceeds the exact portable range.',
      );
    }
    return integer.toInt();
  }
  if (type == JDataType.jsonb.id) {
    try {
      return _freezeJson(jsonDecode(value));
    } on FormatException catch (error) {
      throw ArgumentError('Invalid JSON: ${error.message}');
    }
  }
  throw ArgumentError('Unsupported jcore data type $type.');
}

bool _isInteger(int type) =>
    type == JDataType.int32.id ||
    type == JDataType.int64.id ||
    type == JDataType.datetime.id ||
    type == JDataType.time.id;

BigInt _parseInteger(String value, int type, bool stringMode) {
  if (!RegExp(r'^[+-]?\d+$').hasMatch(value)) {
    throw ArgumentError('Expected an integer.');
  }
  final parsed = BigInt.parse(value);
  final min = type == JDataType.int32.id
      ? BigInt.from(-2147483648)
      : -(BigInt.one << 63);
  final max = type == JDataType.int32.id
      ? BigInt.from(2147483647)
      : (BigInt.one << 63) - BigInt.one;
  if (parsed < min || parsed > max) {
    throw ArgumentError('Integer is out of range.');
  }
  if (!stringMode &&
      const bool.fromEnvironment('dart.library.js_interop') &&
      parsed.abs() > BigInt.from(9007199254740991)) {
    throw ArgumentError('Raw integer exceeds the exact portable range.');
  }
  return parsed;
}

void _checkTextLength(String value, int type) {
  final limit = decodeTextType(type);
  if (limit != null && value.length > limit) {
    throw ArgumentError('Text exceeds length $limit.');
  }
}

void _checkDecimal(Object value, int type) {
  final error = JConverter.validateValue(value, type, 0, 'value');
  if (error != null) throw ArgumentError(error);
}

List<dynamic> _freezeRow(List<dynamic> row, List<int> types) {
  return List<dynamic>.unmodifiable([
    for (var i = 0; i < row.length; i++)
      if (row[i] is BigInt && types[i] == JDataType.int64.id)
        row[i]
      else
        _freezeJson(row[i]),
  ]);
}

dynamic _freezeJson(dynamic value) {
  if (value == null || value is String || value is bool || value is int) {
    return value;
  }
  if (value is double && value.isFinite) return value;
  if (value is List) return List<dynamic>.unmodifiable(value.map(_freezeJson));
  if (value is Map) {
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw ArgumentError('JSON object keys must be strings.');
      }
      result[entry.key as String] = _freezeJson(entry.value);
    }
    return Map<String, dynamic>.unmodifiable(result);
  }
  throw ArgumentError('Value is not JSON encodable.');
}
