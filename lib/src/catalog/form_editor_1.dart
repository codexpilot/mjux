/// Identifies a field by object identity within a Catalog item.
final class FieldKey {}

sealed class FieldSpec {
  const FieldSpec({
    required this.key,
    required this.label,
    this.isRequired = false,
  });

  final FieldKey key;
  final String label;
  final bool isRequired;
}

final class TextFieldSpec extends FieldSpec {
  const TextFieldSpec({
    required super.key,
    required super.label,
    super.isRequired,
  });
}

final class ChoiceFieldSpec extends FieldSpec {
  ChoiceFieldSpec({
    required super.key,
    required super.label,
    required List<String> options,
    super.isRequired,
  }) : options = List.unmodifiable(options) {
    if (this.options.isEmpty ||
        this.options.any((option) => option.trim().isEmpty) ||
        this.options.toSet().length != this.options.length) {
      throw ArgumentError('Choices must be nonblank, unique, and nonempty.');
    }
  }

  final List<String> options;
}

/// Catalog item for editing a configurable set of fields.
final class FormEditor1 {
  FormEditor1({required this.title, required List<FieldSpec> fields})
    : fields = List.unmodifiable(fields) {
    if (title.trim().isEmpty || this.fields.isEmpty) {
      throw ArgumentError('A form must have a title and at least one field.');
    }
    final keys = <FieldKey>{};
    for (final field in this.fields) {
      if (!keys.add(field.key)) {
        throw ArgumentError('A field key cannot occur twice in a form.');
      }
      if (field.label.trim().isEmpty) {
        throw ArgumentError('Every field must have a label.');
      }
    }
  }

  final String title;
  final List<FieldSpec> fields;
}

/// A snapshot of the values at the moment the user requests a save.
final class SaveRequested {
  SaveRequested(Map<FieldKey, String?> values)
    : values = Map.unmodifiable(values);

  final Map<FieldKey, String?> values;
}

sealed class SaveResult {
  const SaveResult();
}

final class SaveSucceeded extends SaveResult {
  const SaveSucceeded();
}

final class SaveFailed extends SaveResult {
  const SaveFailed(this.message);

  final String message;
}
