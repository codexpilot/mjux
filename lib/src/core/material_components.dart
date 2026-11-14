import 'package:material_ui/material_ui.dart';

import 'component_registry.dart';

final class Panel extends CoreComponent {
  const Panel({required this.children});

  final List<Widget> children;
}

final class TextInput extends CoreComponent {
  const TextInput({
    required this.label,
    required this.initialValue,
    required this.error,
    required this.onChanged,
  });

  final String label;
  final String? initialValue;
  final String? error;
  final ValueChanged<String> onChanged;
}

final class ChoiceInput extends CoreComponent {
  const ChoiceInput({
    required this.label,
    required this.options,
    required this.value,
    required this.error,
    required this.canClear,
    required this.onChanged,
  });

  final String label;
  final List<String> options;
  final String? value;
  final String? error;
  final bool canClear;
  final ValueChanged<String?> onChanged;
}

final class ActionButton extends CoreComponent {
  const ActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;
}

ComponentRegistry createMaterialCoreRegistry() {
  return ComponentRegistry()
    ..register<Panel>(
      (panel) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: panel.children,
          ),
        ),
      ),
    )
    ..register<TextInput>(
      (input) => TextFormField(
        initialValue: input.initialValue,
        decoration: InputDecoration(
          labelText: input.label,
          errorText: input.error,
          border: const OutlineInputBorder(),
        ),
        onChanged: input.onChanged,
      ),
    )
    ..register<ChoiceInput>(
      (input) => DropdownButtonFormField<String>(
        initialValue: input.value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: input.label,
          errorText: input.error,
          border: const OutlineInputBorder(),
        ),
        items: [
          if (input.canClear)
            const DropdownMenuItem<String>(child: Text('None')),
          for (final option in input.options)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: input.onChanged,
      ),
    )
    ..register<ActionButton>(
      (action) =>
          FilledButton(onPressed: action.onPressed, child: Text(action.label)),
    );
}
