/// Panel builders for JCore UIX types.
library;

import 'package:material_ui/material_ui.dart';
import 'package:jcore/jux.dart' as jux;

/// Registry of panel builders by UIX ID.
class PanelBuilderRegistry {
  static final _builders = <int, PanelBuilder>{};

  /// Register a builder for a UIX type.
  static void register(int uixId, PanelBuilder builder) {
    _builders[uixId] = builder;
  }

  /// Get a builder for a UIX type.
  static PanelBuilder? get(int uixId) => _builders[uixId];

  /// Build a panel widget for a partial view definition.
  static Widget build(
    BuildContext context,
    jux.PanelDef viewDef,
    jux.ViewModel viewModel,
  ) {
    final builder = get(viewDef.uix.i);
    if (builder == null) {
      return Center(
        child: Text('No builder registered for UIX ${viewDef.uix.code}'),
      );
    }
    return builder(context, viewDef, viewModel);
  }
}

/// Builder function for a panel.
typedef PanelBuilder = Widget Function(
  BuildContext context,
  jux.PanelDef viewDef,
  jux.ViewModel viewModel,
);

/// Collection panel builder with actual data binding.
Widget buildCollectionPanel(
  BuildContext context,
  jux.PanelDef viewDef,
  jux.ViewModel viewModel, {
  VoidCallback? onRefresh,
  void Function(Map<String, dynamic>)? onSelectRow,
  VoidCallback? onCreate,
}) {
  // For collection, we expect a list of records
  final records = viewModel is jux.ComposedViewModel
      ? (viewModel as dynamic).records as List<Map<String, dynamic>>? ?? []
      : <Map<String, dynamic>>[];

  return Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  viewDef.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final cmd in viewDef.commands)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ElevatedButton(
                    onPressed: cmd.command == 'refresh'
                        ? onRefresh
                        : cmd.command == 'create'
                            ? onCreate
                            : null,
                    child: Text(cmd.label),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : viewModel.hasError
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Error: ${viewModel.errorMessage}'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: onRefresh,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : records.isEmpty
                      ? const Center(child: Text('No records'))
                      : ListView.builder(
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final record = records[index];
                            final nameField = viewDef.fields.firstWhere(
                              (f) => f.key == 'name',
                              orElse: () => viewDef.fields.first,
                            );

                            return ListTile(
                              title: Text(record[nameField.key]?.toString() ?? 'Unknown'),
                              subtitle: viewDef.fields.length > 1
                                  ? Text('ID: ${record['i']}')
                                  : null,
                              onTap: onSelectRow != null
                                  ? () => onSelectRow(record)
                                  : null,
                            );
                          },
                        ),
        ),
      ],
    ),
  );
}

/// Inspection panel builder with actual data binding.
Widget buildInspectionPanel(
  BuildContext context,
  jux.PanelDef viewDef,
  jux.ViewModel viewModel, {
  VoidCallback? onEdit,
  VoidCallback? onBack,
}) {
  final selectedRecord = viewModel is jux.ComposedViewModel
      ? viewModel.selectedRecord
      : null;

  return Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  viewDef.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final cmd in viewDef.commands)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ElevatedButton(
                    onPressed: cmd.command == 'edit'
                        ? onEdit
                        : cmd.command == 'back'
                            ? onBack
                            : null,
                    child: Text(cmd.label),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: selectedRecord == null
              ? const Center(child: Text('No record selected'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final field in viewDef.fields)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                field.label,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedRecord[field.key]?.toString() ?? '-',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    ),
  );
}

/// Form panel builder with actual data binding.
Widget buildFormPanel(
  BuildContext context,
  jux.PanelDef viewDef,
  jux.ViewModel viewModel, {
  void Function(String, dynamic)? onFieldChanged,
  VoidCallback? onSave,
  VoidCallback? onCancel,
  VoidCallback? onBack,
}) {
  final draftRecord = viewModel is jux.ComposedViewModel
      ? viewModel.draftRecord
      : null;

  final selectedRecord = viewModel is jux.ComposedViewModel
      ? viewModel.selectedRecord
      : null;

  final record = draftRecord ?? selectedRecord;

  return Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            viewDef.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: record == null
              ? const Center(child: Text('No record selected'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final field in viewDef.fields)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TextFormField(
                            initialValue: record[field.key]?.toString() ?? '',
                            decoration: InputDecoration(
                              labelText: field.label,
                              border: const OutlineInputBorder(),
                            ),
                            readOnly: field.readOnly,
                            onChanged: field.readOnly
                                ? null
                                : (value) {
                                    if (viewModel is jux.ComposedViewModel) {
                                      viewModel.updateDraft(field.key, value);
                                    }
                                  },
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (final cmd in viewDef.commands)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: ElevatedButton(
                    onPressed: cmd.command == 'save'
                        ? onSave
                        : cmd.command == 'cancel'
                            ? onCancel
                            : cmd.command == 'back'
                                ? onBack
                                : null,
                    child: Text(cmd.label),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Register default builders.
void registerDefaultBuilders() {
  PanelBuilderRegistry.register(
    jux.UIX.collectionPanel.i,
    buildCollectionPanel,
  );
  PanelBuilderRegistry.register(
    jux.UIX.inspectionPanel.i,
    buildInspectionPanel,
  );
  PanelBuilderRegistry.register(
    jux.UIX.formPanel.i,
    buildFormPanel,
  );
}
