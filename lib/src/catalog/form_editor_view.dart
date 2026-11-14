import 'package:material_ui/material_ui.dart';

import '../core/material_components.dart';
import 'form_editor_1.dart';

final _core = createMaterialCoreRegistry();

final class FormEditorView extends StatelessWidget {
  const FormEditorView({
    super.key,
    required this.item,
    required this.values,
    required this.errors,
    required this.isSaving,
    required this.canSave,
    required this.statusMessage,
    required this.onChanged,
    required this.onSave,
  });

  final FormEditor1 item;
  final Map<FieldKey, String?> values;
  final Map<FieldKey, String> errors;
  final bool isSaving;
  final bool canSave;
  final String? statusMessage;
  final void Function(FieldKey, String?) onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final message = statusMessage;
    return _core.build(
      Panel(
        children: [
          Semantics(
            header: true,
            child: Text(
              item.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),
          for (final field in item.fields)
            Padding(
              key: ValueKey(field.key),
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildField(field),
            ),
          _core.build(
            ActionButton(
              label: isSaving ? 'Saving…' : 'Save',
              onPressed: canSave && !isSaving ? onSave : null,
            ),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Semantics(liveRegion: true, child: Text(message)),
            ),
        ],
      ),
    );
  }

  Widget _buildField(FieldSpec field) {
    final value = values[field.key];
    final error = errors[field.key];
    return _core.build(switch (field) {
      TextFieldSpec() => TextInput(
        label: field.label,
        initialValue: value,
        error: error,
        onChanged: (value) => onChanged(field.key, value),
      ),
      ChoiceFieldSpec(:final options) => ChoiceInput(
        label: field.label,
        options: options,
        value: value,
        error: error,
        canClear: !field.isRequired,
        onChanged: (value) => onChanged(field.key, value),
      ),
    });
  }
}
