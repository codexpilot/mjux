/// Desktop panel builders with compact keyboard+mouse optimized sizing.
library;

import 'package:material_ui/material_ui.dart';
import 'package:jcore/jux.dart' as jux;

/// Desktop collection panel with compact sizing.
Widget buildCollectionPanelDesktop(
  BuildContext context,
  jux.PanelDef viewDef,
  jux.ViewModel viewModel, {
  VoidCallback? onRefresh,
  void Function(Map<String, dynamic>)? onSelectRow,
  VoidCallback? onCreate,
}) {
  final records = viewModel is jux.ComposedViewModel
      ? (viewModel as dynamic).records as List<Map<String, dynamic>>? ?? []
      : <Map<String, dynamic>>[];

  return Card(
    margin: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Compact header: 32px height
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  viewDef.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final cmd in viewDef.commands)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: SizedBox(
                    height: 24,
                    child: TextButton(
                      onPressed: cmd.command == 'refresh'
                          ? onRefresh
                          : cmd.command == 'create'
                              ? onCreate
                              : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        cmd.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: viewModel.isLoading
              ? const Center(child: CircularProgressIndicator())
              : viewModel.hasError
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Error: ${viewModel.errorMessage}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 28,
                            child: ElevatedButton(
                              onPressed: onRefresh,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: const Size(0, 28),
                              ),
                              child: const Text('Retry', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : records.isEmpty
                      ? const Center(
                          child: Text('No records', style: TextStyle(fontSize: 12)),
                        )
                      : ListView.builder(
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final record = records[index];
                            final nameField = viewDef.fields.firstWhere(
                              (f) => f.key == 'n',
                              orElse: () => viewDef.fields.first,
                            );

                            return InkWell(
                              onTap: onSelectRow != null
                                  ? () => onSelectRow(record)
                                  : null,
                              child: Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        record[nameField.key]?.toString() ?? 'Unknown',
                                        style: const TextStyle(fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (viewDef.fields.length > 1)
                                      Text(
                                        'ID: ${record['i']}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Theme.of(context).textTheme.bodySmall?.color,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    ),
  );
}

/// Desktop inspection panel with compact sizing.
Widget buildInspectionPanelDesktop(
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
    margin: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Compact header: 32px height
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  viewDef.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final cmd in viewDef.commands)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: SizedBox(
                    height: 24,
                    child: TextButton(
                      onPressed: cmd.command == 'edit'
                          ? onEdit
                          : cmd.command == 'back'
                              ? onBack
                              : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        cmd.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: selectedRecord == null
              ? const Center(
                  child: Text('No record selected', style: TextStyle(fontSize: 12)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final field in viewDef.fields)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                field.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedRecord[field.key]?.toString() ?? '-',
                                style: const TextStyle(fontSize: 13),
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

/// Desktop form panel with compact sizing.
Widget buildFormPanelDesktop(
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
    margin: EdgeInsets.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Compact header: 32px height
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Text(
            viewDef.title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: record == null
              ? const Center(
                  child: Text('No record selected', style: TextStyle(fontSize: 12)),
                )
              : SingleChildScrollView(
                  key: ValueKey(record['i']), // Force rebuild when record changes
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final field in viewDef.fields)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SizedBox(
                            height: 32,
                            child: TextFormField(
                              initialValue: record[field.key]?.toString() ?? '',
                              decoration: InputDecoration(
                                labelText: field.label,
                                labelStyle: const TextStyle(fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                              readOnly: field.readOnly || draftRecord == null,
                              onChanged: (field.readOnly || draftRecord == null)
                                  ? null
                                  : (value) {
                                      if (viewModel is jux.ComposedViewModel) {
                                        viewModel.updateDraft(field.key, value);
                                      }
                                    },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        // Compact footer with buttons
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              for (final cmd in viewDef.commands)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SizedBox(
                    height: 28,
                    child: ElevatedButton(
                      onPressed: cmd.command == 'save'
                          ? onSave
                          : cmd.command == 'cancel'
                              ? onCancel
                              : cmd.command == 'back'
                                  ? onBack
                                  : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        cmd.label,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
