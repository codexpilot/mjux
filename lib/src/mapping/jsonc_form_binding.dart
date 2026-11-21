import 'dart:convert';

import 'package:jcore/jcore.dart';

import '../catalog/form_editor_1.dart';

/// Binds form fields to one row of JSONC using JCore's current type catalog.
///
/// The binding snapshots its input. Use [initialValues] when opening a surface,
/// then pass its save request to [toJsonC]. Unbound columns and other rows are
/// preserved. Schema IDs must be recognized by [DataTypeRegistry]; legacy
/// Group 3 IDs are rejected. Edited decimals become [Numeric] values when the
/// JSONC number mode uses strings. Values are displayed as text; datetime and
/// time use JCore's integer representations, not localized dates or times.
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
    final schemaErrors = <String>[];
    if (schema.isEmpty) schemaErrors.add('Schema cannot be empty');
    for (final entry in schema.entries) {
      if (entry.key.isEmpty) {
        schemaErrors.add('Column name cannot be empty');
      }
      if (!DataTypeRegistry.isValid(entry.value)) {
        schemaErrors.add(
          'Invalid jcore data type for column "${entry.key}": ${entry.value}',
        );
      }
    }
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
  if (_isTextType(type)) {
    if (value is! String) {
      throw ArgumentError('Expected a string for type $type.');
    }
    _checkTextLength(value, type);
    return value;
  }
  if (type == DataType.boolean.id) {
    if (value is! bool) throw ArgumentError('Expected a boolean.');
    return value.toString();
  }
  if (_isInteger(type)) {
    final stringMode = type == DataType.int64.id && jsonc.useBigIntStrings;
    if (stringMode ? value is! BigInt : value is! int) {
      throw ArgumentError('Unexpected integer representation for type $type.');
    }
    final text = value.toString();
    _parseInteger(text, type, stringMode);
    return text;
  }
  if (DataTypeRegistry.isValidNumeric(type)) {
    if (jsonc.useNumericStrings
        ? value is! String && value is! Numeric
        : value is! num && value is! Numeric) {
      throw ArgumentError('Unexpected numeric representation.');
    }
    final text = value.toString();
    _checkDecimal(value as Object, type);
    if (value is num && !value.isFinite) {
      throw ArgumentError('Non-finite numeric value.');
    }
    return text;
  }
  if (type == DataType.jsonb.id) return jsonEncode(value);
  throw ArgumentError('Unsupported jcore data type $type.');
}

dynamic _parseValue(String? value, int type, JsonC jsonc) {
  if (value == null) return null;
  if (_isTextType(type)) {
    _checkTextLength(value, type);
    return value;
  }
  if (type == DataType.boolean.id) {
    if (value == 'true') return true;
    if (value == 'false') return false;
    throw ArgumentError('Boolean must be true or false.');
  }
  if (_isInteger(type)) {
    final stringMode = type == DataType.int64.id && jsonc.useBigIntStrings;
    final integer = _parseInteger(value, type, stringMode);
    return stringMode ? integer : integer.toInt();
  }
  if (DataTypeRegistry.isValidNumeric(type)) {
    _checkDecimal(value, type);
    if (jsonc.useNumericStrings) {
      final decoded = DataTypeRegistry.decodeNumeric(type)!;
      final decimal = _expandDecimal(value);
      final scale = decoded.scale ?? _decimalScale(decimal);
      try {
        return Numeric.fromString(decimal, scale);
      } on FormatException catch (error) {
        throw ArgumentError('Invalid exact decimal: ${error.message}');
      }
    }
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
  if (type == DataType.jsonb.id) {
    try {
      return _freezeJson(jsonDecode(value));
    } on FormatException catch (error) {
      throw ArgumentError('Invalid JSON: ${error.message}');
    }
  }
  throw ArgumentError('Unsupported jcore data type $type.');
}

bool _isInteger(int type) =>
    type == DataType.smallint.id ||
    type == DataType.int32.id ||
    type == DataType.int64.id ||
    type == DataType.datetime.id ||
    type == DataType.time.id;

BigInt _parseInteger(String value, int type, bool stringMode) {
  if (!RegExp(r'^[+-]?\d+$').hasMatch(value)) {
    throw ArgumentError('Expected an integer.');
  }
  final parsed = BigInt.parse(value);
  final bits = type == DataType.smallint.id
      ? 16
      : type == DataType.int32.id
      ? 32
      : 64;
  final limit = BigInt.one << (bits - 1);
  final min = -limit;
  final max = limit - BigInt.one;
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
  final limit = DataTypeRegistry.decodeText(type);
  if (limit != null && value.length > limit) {
    throw ArgumentError('Text exceeds length $limit.');
  }
}

void _checkDecimal(Object value, int type) {
  final error = JConverter.validateValue(value, type, 0, 'value');
  if (error != null) throw ArgumentError(error);
}

bool _isTextType(int type) =>
    DataTypeRegistry.isValidText(type) ||
    type == DataType.uuid.id ||
    type == DataType.text0z.id;

int _decimalScale(String value) {
  final point = value.indexOf('.');
  return point < 0 ? 0 : value.length - point - 1;
}

String _expandDecimal(String value) {
  final input = value.trim();
  final match = RegExp(r'^([+-]?)(\d*)(?:\.(\d*))?(?:[eE]([+-]?\d+))?$')
      .firstMatch(input);
  if (match == null) throw ArgumentError('Expected an exact decimal value.');

  final whole = match.group(2)!;
  final fraction = match.group(3) ?? '';
  final digits = '$whole$fraction';
  if (digits.isEmpty) throw ArgumentError('Expected an exact decimal value.');

  final exponentText = match.group(4);
  final exponent = exponentText == null ? 0 : int.tryParse(exponentText);
  if (exponent == null || exponent.abs() > 10000) {
    throw ArgumentError('Decimal exponent is out of range.');
  }

  final decimalPosition = whole.length + exponent;
  final String expanded;
  if (decimalPosition <= 0) {
    expanded = '0.${'0' * -decimalPosition}$digits';
  } else if (decimalPosition >= digits.length) {
    expanded = '$digits${'0' * (decimalPosition - digits.length)}';
  } else {
    expanded =
        '${digits.substring(0, decimalPosition)}.'
        '${digits.substring(decimalPosition)}';
  }
  return '${match.group(1)}$expanded';
}

List<dynamic> _freezeRow(List<dynamic> row, List<int> types) {
  return List<dynamic>.unmodifiable([
    for (var i = 0; i < row.length; i++)
      if (row[i] is BigInt && types[i] == DataType.int64.id)
        row[i]
      else
        _freezeJson(row[i]),
  ]);
}

dynamic _freezeJson(dynamic value) {
  if (value == null ||
      value is String ||
      value is bool ||
      value is int ||
      value is Numeric) {
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
