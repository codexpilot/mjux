# Prototype API

MJUX `0.1.0` exposes its supported types through `package:mjux/mjux.dart`.
Use a local path dependency to evaluate the package with Flutter 3.50.0 or
later. Flutter 3.50.0 bundles Dart 3.14.0. The example declares the dependency
and runs a complete host app. [Example manifest](../../example/pubspec.yaml)

| Type | Use |
| --- | --- |
| `FormEditor1` | Defines a titled form with an ordered list of `FieldSpec` objects. |
| `FieldKey` | Identifies a field by object identity. Reuse the same key instance in the specification, initial values, and save handler. |
| `TextFieldSpec` | Defines a text field with a key, label, and optional `isRequired` flag. |
| `ChoiceFieldSpec` | Defines a choice field with a key, label, options, and optional `isRequired` flag. |
| `Utility` | Opens a `Surface` from a `FormEditor1`, initial values, and an async save handler. |
| `SurfaceView` | Renders a surface inside the host Flutter app. |
| `Surface` | Owns one instance's interaction state. The host calls `dispose()` when finished with it. |
| `SaveRequested` | Contains an immutable snapshot of the draft values at submission. |
| `SaveSucceeded` / `SaveFailed` | Report whether the host saved the snapshot. `SaveFailed` takes a message to display. |

Create the definition and surfaces outside `build`. Mount each surface in one
`SurfaceView(surface: surface)` at a time inside a `MaterialApp` from
`package:material_ui/material_ui.dart`. Unmount the view and dispose the
surface when finished. Reuse the same definition to open multiple independent
surfaces. The example opens them in `initState` and releases them in
`dispose`. [Example app](../../example/lib/main.dart)

```dart
import 'package:mjux/mjux.dart';

final name = FieldKey();
final item = FormEditor1(
  title: 'Plant details',
  fields: [TextFieldSpec(key: name, label: 'Plant name', isRequired: true)],
);
final surface = const Utility().open(
  item,
  initialValues: {name: 'Basil'},
  onSave: (request) async {
    // Use request.values[name] to persist the draft in the host app.
    return const SaveSucceeded();
  },
);
```

### Configuration and values

- A form requires a nonblank title and at least one field. Field keys must be
  unique within the form, and labels must be nonblank.
- Choice options must be nonempty, unique, and nonblank. Initial values must
  use keys declared in the form and any non-null choice must be an option.
  Violations of these configuration rules throw `ArgumentError`.
- Initial values and save snapshots use `Map<FieldKey, String?>`. Omitted keys
  stay absent until edited, and a present key can hold `null`. An optional
  choice can be cleared to `null`. Clearing text produces an empty string.
- Required fields reject missing, null, or whitespace-only values. Errors
  appear after a field is touched or an edited form is submitted.

### Saving and lifecycle

Save is enabled when the draft differs from the last saved values and there is
no pending save. An invalid draft shows required-field errors. A valid draft
passes a snapshot to the async `onSave` callback. The host handles persistence
and business rules. If the callback throws, the form displays a generic save
failure message and keeps the draft available for retry.

Editing can continue while a save is pending. On success, the submitted
snapshot becomes the saved baseline, so newer edits stay in the draft and
remain unsaved. A rejected save keeps the last saved baseline and the draft.
Disposal stops late save results from updating the surface. The host manages
the lifetime of any persistence work it starts.

The current API supports direct `FormEditor1` selection and local state per
surface. The plan tracks dynamic Catalog lookup, host refresh, and external
protocol adapters. [Working plan](../plan/README.md)
