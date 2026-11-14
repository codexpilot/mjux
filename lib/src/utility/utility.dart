import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../catalog/form_editor_1.dart';
import '../catalog/form_editor_view.dart';

/// Opens independent surfaces for supported Catalog items.
final class Utility {
  const Utility();

  Surface open(
    FormEditor1 item, {
    required Map<FieldKey, String?> initialValues,
    required Future<SaveResult> Function(SaveRequested) onSave,
  }) {
    final fields = {for (final field in item.fields) field.key: field};
    for (final MapEntry(key: key, value: value) in initialValues.entries) {
      final field = fields[key];
      if (field == null) {
        throw ArgumentError('Initial values contain an unknown field key.');
      }
      if (field is ChoiceFieldSpec &&
          value != null &&
          !field.options.contains(value)) {
        throw ArgumentError('Invalid initial choice for ${field.label}.');
      }
    }
    return Surface._(item, initialValues, onSave);
  }
}

/// One running instance. The host owns its lifetime and must dispose it.
final class Surface {
  Surface._(this._item, Map<FieldKey, String?> initialValues, this._onSave)
    : _draft = Map.of(initialValues),
      _saved = Map.unmodifiable(initialValues);

  final FormEditor1 _item;
  final Future<SaveResult> Function(SaveRequested) _onSave;
  final _changes = _SurfaceChanges();
  final Map<FieldKey, String?> _draft;
  final _touched = <FieldKey>{};
  Map<FieldKey, String?> _saved;
  bool _saving = false;
  bool _disposed = false;
  bool _submitted = false;
  String? _statusMessage;

  bool get _dirty => !mapEquals(_draft, _saved);

  Map<FieldKey, String> get _visibleErrors => {
    for (final field in _item.fields)
      if (field.isRequired &&
          (_submitted || _touched.contains(field.key)) &&
          (_draft[field.key]?.trim().isEmpty ?? true))
        field.key: 'Required',
  };

  void _change(FieldKey key, String? value) {
    if (_disposed) return;
    _touched.add(key);
    _draft[key] = value;
    _statusMessage = null;
    _changes.changed();
  }

  Future<void> _save() async {
    if (_disposed || _saving || !_dirty) return;
    _submitted = true;
    if (_visibleErrors.isNotEmpty) {
      _changes.changed();
      return;
    }

    final request = SaveRequested(_draft);
    _saving = true;
    _statusMessage = null;
    _changes.changed();

    final SaveResult result;
    try {
      result = await _onSave(request);
    } catch (_) {
      _completeSave(request, const SaveFailed('Could not save. Try again.'));
      return;
    }
    _completeSave(request, result);
  }

  void _completeSave(SaveRequested request, SaveResult result) {
    if (_disposed) return;
    _saving = false;
    switch (result) {
      case SaveSucceeded():
        _saved = request.values;
        _statusMessage = _dirty ? 'Saved. New edits are unsaved.' : 'Saved.';
      case SaveFailed(:final message):
        _statusMessage = message;
    }
    _changes.changed();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _changes.dispose();
  }
}

final class _SurfaceChanges extends ChangeNotifier {
  void changed() => notifyListeners();
}

/// Mounts a surface inside a host Flutter application.
final class SurfaceView extends StatelessWidget {
  const SurfaceView({super.key, required this.surface});

  final Surface surface;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: surface._changes,
      builder: (context, _) => FormEditorView(
        key: ObjectKey(surface),
        item: surface._item,
        values: surface._draft,
        errors: surface._visibleErrors,
        isSaving: surface._saving,
        canSave: surface._dirty,
        statusMessage: surface._statusMessage,
        onChanged: surface._change,
        onSave: () => unawaited(surface._save()),
      ),
    );
  }
}
