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
| `JsonCFormBinding` | Maps a decoded JX row to form values and applies edits to a new row snapshot. |

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

### JCore JX mapping

MJUX uses JCore's Dart type registry and exact numeric values. Declare JCore
as a direct dependency if the app imports it. `JsonCFormBinding` accepts the
ordered schema, decoded positional rows, and four-digit JX encoding. Column
order in the schema must match the decoded row order. Each form key maps to
a distinct column. [JCore](https://github.com/codexpilot/jcore)

```dart
import 'package:jcore/jcore.dart';
import 'package:mjux/mjux.dart';

final name = FieldKey();
final form = FormEditor1(
  title: 'Plant details',
  fields: [TextFieldSpec(key: name, label: 'Plant name', isRequired: true)],
);
final binding = JsonCFormBinding(
  form: form,
  encoding: 8000,
  jv: 1,
  jid: 12345,
  schema: {'name': DataType.text.id},
  data: [
    ['Basil'],
  ],
  rowIndex: 0,
  columns: {name: 'name'},
);
final surface = const Utility().open(
  form,
  initialValues: binding.initialValues,
  onSave: (request) async {
    try {
      final updated = binding.toJsonC(request);
      // Use updated.data and updated.encoding when saving the result.
      return const SaveSucceeded();
    } on ArgumentError {
      return const SaveFailed('Check the entered values.');
    }
  },
);
```

The form edits string values and converts them using JCore schema types. It
supports boolean, SMALLINT, INT32, INT64, datetime, time, text, UUID, NUMERIC,
and JSONB values. JSONB fields use JSON text. Datetime and time use decoded
integer values. Booleans use `true` or `false`. The binding checks text length,
numeric precision, and numeric scale when the schema specifies them.

The binding snapshots its input. `toJsonC` returns a record containing
`schema`, `data`, `encoding`, and optional result metadata `jv` and `jid`.
It preserves unbound columns, other rows, and unchanged cells. Create a new
binding from newly saved data when subsequent saves need to include other
changes. The constructor validates encoding, metadata, row shape, and column
mappings. A save must contain exactly the bound fields. Invalid inputs and
unrepresentable edits throw `ArgumentError`.

With `N=0`, the binding stores edited decimals as exact `Numeric` values.
With `N=1`, it accepts NUMERIC edits as integers within ±9007199254740991.
For INT64, the binding uses `BigInt` with `L=0` and `int` with `L=1`.
Use `JxCodec` with the original JX schema when serializing the edited rows.

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
