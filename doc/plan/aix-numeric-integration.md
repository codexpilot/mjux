# AIX Numeric Integration for MJUX

**Date:** 2026-01-23  
**Status:** Historical proposal, superseded by JCore `jdata`
**Relates to:** [Core backlog priority #3](material-ui-component-gaps.md#prioritized-core-component-backlog)

## Historical overview

This document records the original AIX-owned `Numeric` proposal. `Numeric` now
lives in JCore and MJUX consumes it through `package:jcore/jcore.dart`. The
architecture below is a design sketch, not the current MJUX API contract.

MJUX originally planned to leverage AIX's high-performance `Numeric` class for exact decimal arithmetic. This provides financial and clinical precision without floating-point loss, critical for ERP, POS, EMR, and EHR workflows.

## AIX Numeric Class Capabilities

### Core Features

- **Exact decimal representation** - No floating-point loss
- **Arbitrary precision** - Handles large integers and precise decimals
- **Hybrid int/BigInt storage** - Uses int64 when possible for performance
- **Scale-based arithmetic** - Each value has fixed decimal places
- **Rounding modes** - towardZero, halfEven, halfAwayFromZero
- **Locale-agnostic** - Parses and formats decimal strings exactly

### Performance Optimizations

1. **Cached scale powers** - Avoids repeated `BigInt.pow()` calculations
2. **Fast paths for common scales** - Scale 2 and 4 optimized (banking)
3. **Overflow detection** - Checks before operations, upgrades to BigInt only when needed
4. **Batch operations** - Specialized `sumAll()` for aggregations
5. **Inline operations** - Reduces function call overhead for same-scale arithmetic

### String Serialization

```dart
// Parse exact decimal
final price = Numeric.fromString('123.45', 2);  // Scale 2 (cents)

// Format for display
print(price.toDisplay());  // "123.45"
print(price.toDisplay(0)); // "123" (rounded)

// JSON serialization (string-based, no precision loss)
final json = price.toJson();  // "123.45"
final parsed = Numeric.fromJson(json, 2);
```

**Critical:** JSON numbers can lose precision. AIX Numeric uses **string representation** in JSON to preserve exactness.

## MJUX Integration Architecture

### Layer Placement

```
┌─────────────────────────────────────┐
│ MJUX Catalog (Public API)          │
│ ├── DecimalFieldSpec                │
│ │   (precision, min/max, unit)      │
│ └── QuantityFieldSpec               │
│     (precision, unit, range)        │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ MJUX Utility (State Management)    │
│ ├── Surface holds Numeric values    │
│ ├── Validation uses Numeric ops     │
│ └── Events carry Numeric snapshots  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│ MJUX Core (Widget Builders)        │
│ ├── DecimalInput (material_ui)     │
│ │   - Parses user input to Numeric │
│ │   - Formats Numeric for display  │
│ │   - Handles locale separators    │
│ └── QuantityInput                   │
│     - Plus unit labels/pickers     │
└─────────────────────────────────────┘
```

**Key Decision:** Numeric lives in **Utility layer**, not Core. This keeps precision handling in business logic, not UI widgets.

### Catalog Layer: Field Specifications

```dart
// Catalog item configuration
final class DecimalFieldSpec extends FieldSpec {
  const DecimalFieldSpec({
    required super.key,
    required super.label,
    required this.precision,    // 2, 4, 6 typical
    this.min,                   // Numeric? for exact bounds
    this.max,                   // Numeric?
    this.unit,                  // 'USD', 'EUR', 'kg', etc.
    super.isRequired,
  });
  
  final int precision;
  final Numeric? min;
  final Numeric? max;
  final String? unit;
}

// Money field specialization
final class MoneyFieldSpec extends DecimalFieldSpec {
  const MoneyFieldSpec({
    required super.key,
    required super.label,
    required String currency,   // ISO 4217 code
    super.isRequired,
  }) : super(
    precision: 2,              // Standard currency precision
    unit: currency,
    min: Numeric.fromString('0', 2),  // Non-negative
  );
}

// Quantity with units
final class QuantityFieldSpec extends DecimalFieldSpec {
  const QuantityFieldSpec({
    required super.key,
    required super.label,
    required this.unitOptions,  // ['kg', 'g', 'mg'] or ['L', 'mL']
    this.defaultUnit,
    super.precision = 4,       // Higher precision for quantities
    super.min,
    super.max,
    super.isRequired,
  }) : super(unit: defaultUnit);
  
  final List<String> unitOptions;
  final String? defaultUnit;
}
```

### Utility Layer: Value Storage

```dart
// Surface state holds Numeric values separately from text
final class Surface {
  Surface._(
    this._item,
    Map<FieldKey, dynamic> initialValues,  // Can contain Numeric
    this._onSave,
  ) {
    // Separate storage by field type
    for (final field in _item.fields) {
      if (field is DecimalFieldSpec) {
        final value = initialValues[field.key];
        _numericValues[field.key] = value is Numeric 
          ? value 
          : (value is String ? Numeric.fromString(value, field.precision) : null);
      } else if (field is TextFieldSpec) {
        _textValues[field.key] = initialValues[field.key] as String?;
      } else if (field is ChoiceFieldSpec) {
        _choiceValues[field.key] = initialValues[field.key] as String?;
      }
    }
  }
  
  // Type-safe storage
  final Map<FieldKey, Numeric?> _numericValues = {};
  final Map<FieldKey, String?> _textValues = {};
  final Map<FieldKey, String?> _choiceValues = {};
  
  // Validation uses Numeric operations
  Map<FieldKey, String> get _visibleErrors {
    final errors = <FieldKey, String>{};
    
    for (final field in _item.fields) {
      if (_submitted || _touched.contains(field.key)) {
        if (field is DecimalFieldSpec) {
          final value = _numericValues[field.key];
          
          if (field.isRequired && value == null) {
            errors[field.key] = 'Required';
          } else if (value != null) {
            if (field.min != null && value < field.min!) {
              errors[field.key] = 'Minimum ${field.min!.toDisplay()}';
            }
            if (field.max != null && value > field.max!) {
              errors[field.key] = 'Maximum ${field.max!.toDisplay()}';
            }
          }
        }
        // ... other field types
      }
    }
    
    return errors;
  }
  
  // Save event carries Numeric values
  Future<void> _save() async {
    // ...
    final snapshot = SaveRequested(
      textValues: Map.unmodifiable(_textValues),
      numericValues: Map.unmodifiable(_numericValues),
      choiceValues: Map.unmodifiable(_choiceValues),
    );
    // ...
  }
}

// Updated save event
final class SaveRequested {
  SaveRequested({
    required Map<FieldKey, String?> textValues,
    required Map<FieldKey, Numeric?> numericValues,
    required Map<FieldKey, String?> choiceValues,
  }) : textValues = Map.unmodifiable(textValues),
       numericValues = Map.unmodifiable(numericValues),
       choiceValues = Map.unmodifiable(choiceValues);
  
  final Map<FieldKey, String?> textValues;
  final Map<FieldKey, Numeric?> numericValues;
  final Map<FieldKey, String?> choiceValues;
}
```

### Core Layer: Widget Implementation

```dart
// Core component contract
final class DecimalInput extends CoreComponent {
  const DecimalInput({
    required this.label,
    required this.precision,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.unit,
    required this.error,
    required this.onChanged,
  });
  
  final String label;
  final int precision;
  final Numeric? initialValue;
  final Numeric? min;
  final Numeric? max;
  final String? unit;  // Display after field: "USD", "kg"
  final String? error;
  final ValueChanged<Numeric?> onChanged;
}

// material_ui implementation in Core registry
ComponentRegistry.register<DecimalInput>((input) {
  return TextFormField(
    initialValue: input.initialValue?.toDisplay(),
    decoration: InputDecoration(
      labelText: input.label,
      suffixText: input.unit,  // "USD" shown after input
      errorText: input.error,
      border: const OutlineInputBorder(),
    ),
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [
      _DecimalTextInputFormatter(
        precision: input.precision,
        min: input.min,
        max: input.max,
      ),
    ],
    onChanged: (text) {
      if (text.isEmpty) {
        input.onChanged(null);
        return;
      }
      
      try {
        final value = Numeric.fromString(text, input.precision);
        input.onChanged(value);
      } catch (e) {
        // Invalid format - Core handles display, Utility validates
        input.onChanged(null);
      }
    },
  );
});

// Locale-aware formatter (handles "," vs "." separators)
class _DecimalTextInputFormatter extends TextInputFormatter {
  _DecimalTextInputFormatter({
    required this.precision,
    this.min,
    this.max,
  });
  
  final int precision;
  final Numeric? min;
  final Numeric? max;
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow partial entry: "-", "12.", "12.3" (even if precision is 2)
    // Utility validates on blur/submit
    
    final text = newValue.text;
    if (text.isEmpty || text == '-') return newValue;
    
    // Normalize separator (support both "," and ".")
    final normalized = text.replaceAll(',', '.');
    
    // Count decimal places (allow during typing)
    final parts = normalized.split('.');
    if (parts.length > 2) return oldValue;  // Multiple decimals invalid
    
    // Allow partial decimal entry
    if (parts.length == 2 && parts[1].length > precision) {
      // Silently truncate excess decimals during typing
      return TextEditingValue(
        text: '${parts[0]}.${parts[1].substring(0, precision)}',
        selection: TextSelection.collapsed(
          offset: parts[0].length + 1 + precision,
        ),
      );
    }
    
    return newValue;
  }
}
```

## Optional External Formats

The current numeric work targets the MJUX Dart API. A2UI provides design
ideas but does not require an adapter. If a future external format carries
exact decimals or large integers, define its representation explicitly and
verify precision-preserving round trips. Canonical decimal strings are one
possible representation. A2UI's Basic Catalog includes a numeric TextField
variant; specialized scale, currency, and unit behavior would need an
explicit contract if A2UI integration is pursued.

## Dataset Integration

Dataset already has decimal handling in `format_transformer.dart` and `schema_bundle.dart`. MJUX bridges them:

```dart
// Dataset → MJUX: Convert Dataset decimal to Numeric
final datasetValue = record.getDecimalField('unit_price');
final numericValue = Numeric.fromString(datasetValue.toString(), 2);

final surface = Utility().open(
  FormEditor1(fields: [
    DecimalFieldSpec(
      key: priceKey,
      label: 'Unit Price',
      precision: 2,
      unit: 'USD',
    ),
  ]),
  initialValues: {priceKey: numericValue},
  onSave: (request) async {
    final price = request.numericValues[priceKey]!;
    // MJUX → Dataset: Convert Numeric to Dataset format
    record.setDecimalField('unit_price', price.toDisplay());
    return const SaveSucceeded();
  },
);
```

## Validation Rules

### Field-Level Validation (Utility)

```dart
// Automatic precision validation
if (value.scale > field.precision) {
  throw ValidationError('Exceeds precision ${field.precision}');
}

// Range validation using Numeric operators
if (field.min != null && value < field.min!) {
  errors[field.key] = 'Minimum ${field.min!.toDisplay()}';
}

if (field.max != null && value > field.max!) {
  errors[field.key] = 'Maximum ${field.max!.toDisplay()}';
}
```

### Host-Level Validation (Dataset)

```dart
onSave: (request) async {
  final price = request.numericValues[priceKey]!;
  final quantity = request.numericValues[quantityKey]!;
  
  // Business rule: Total cannot exceed credit limit
  final total = price.multiplyBy(quantity);
  final creditLimit = Numeric.fromString('10000.00', 2);
  
  if (total > creditLimit) {
    return SaveFailed('Total ${total.toDisplay(2)} exceeds credit limit');
  }
  
  // Persist with exact precision
  await database.saveOrder(
    price: price.toJson(),  // String representation
    quantity: quantity.toJson(),
  );
  
  return const SaveSucceeded();
}
```

## Migration Path

### Phase 1: Text-Only (Current Prototype)

```dart
// Current: Everything is String
Map<FieldKey, String?> values;
```

### Phase 2: Add Numeric Support

```dart
// Add DecimalFieldSpec alongside TextFieldSpec
// Separate storage in Surface
Map<FieldKey, Numeric?> numericValues;
Map<FieldKey, String?> textValues;
```

### Phase 3: Specialized Field Types

```dart
// MoneyFieldSpec (currency-aware)
// QuantityFieldSpec (unit conversion)
// PercentageFieldSpec (0-100 range, display with %)
```

## Performance Characteristics

From AIX Numeric implementation:

| Operation | Same Scale (int) | Same Scale (BigInt) | Different Scales |
|-----------|------------------|---------------------|------------------|
| Addition | ~10ns (fast path) | ~100ns | ~200ns |
| Comparison | ~5ns (fast path) | ~50ns | ~100ns |
| Parsing | ~500ns (int path) | ~1µs | ~1µs |
| Formatting | ~300ns | ~800ns | ~800ns |

**Batch operations:**
- `sumAll([1000 values])` - Uses specialized algorithm, ~10x faster than reduce
- Overflow detection prevents silent int64 wraparound
- Scale-2 and scale-4 fast paths optimize banking workflows

## Open Questions

1. **Locale-aware display formatting**
   - Should MJUX handle "1.234,56" (European) vs "1,234.56" (US)?
   - Or rely on Dataset's existing format_transformer?
   
2. **Unit conversion**
   - Should QuantityFieldSpec support automatic conversion (kg ↔ g)?
   - Or keep unit pure metadata for host to interpret?

3. **Rounding mode defaults**
   - Banking typically uses `halfEven` (banker's rounding)
   - Should be configurable per field or global default?

4. **Large integer handling**
   - AIX Numeric handles arbitrarily large integers
   - Should MJUX expose separate `LargeIntFieldSpec` or use `DecimalFieldSpec` with precision 0?

## References

- [Core Component Backlog Priority #3](material-ui-component-gaps.md) - Typed form fields requirement
- [A2UI v1.0 Basic Catalog](https://a2ui.org/specification/v1.0-basic-catalog-implementation-guide/) - TextField specification
- Dataset `lib/core/format/format_transformer.dart` - Existing decimal handling
- Dataset `lib/core/schema/schema_bundle.dart` - Field metadata
