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
| `JsonCFormBinding` | Maps a row of a jcore `JsonC` to form values and applies a save snapshot to a new `JsonC`. |

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

### jcore JSONC mapping

MJUX depends on [jcore](https://github.com/codexpilot/jcore) 2.0.0 for its Dart
data types and JSONC format. Its Git dependency is pinned in the package manifest.
`JsonCFormBinding` maps every form key to a distinct column in a full JSONC
object (one with both schema and data). Declare jcore as a direct dependency
of an app that imports it. Import jcore to construct or decode a `JsonC`, then
use the binding to open the form:

```dart
import 'package:jcore/jcore.dart';
import 'package:mjux/mjux.dart';

final name = FieldKey();
final form = FormEditor1(
  title: 'Plant details',
  fields: [TextFieldSpec(key: name, label: 'Plant name', isRequired: true)],
);
final jsonc = JsonC(
  jv: 1,
  jid: 12345,
  schema: {'name': JDataType.text.id},
  data: [
    ['Basil'],
  ],
);
final binding = JsonCFormBinding(
  form: form,
  jsonc: jsonc,
  rowIndex: 0,
  columns: {name: 'name'},
);
final surface = const Utility().open(
  form,
  initialValues: binding.initialValues,
  onSave: (request) async {
    try {
      final updated = binding.toJsonC(request);
      // Persist updated, for example by sending updated.toJson() to the host.
      return const SaveSucceeded();
    } on ArgumentError {
      return const SaveFailed('Check the entered values.');
    }
  },
);
```

The form edits string values; the binding converts mapped cells according to
their jcore schema types when loading and saving. It supports boolean, int32,
int64, datetime, time, text, UUID, TEXT0Z, numeric, and JSONB values. JSONB
fields are edited as JSON text. JSONC number-format modes determine whether
numeric and int64 values are represented as strings. Datetime and time use
jcore's integer storage values, not formatted dates or times. Booleans use
`true` or `false`. Text and numeric schema length or precision constraints
are checked when applicable.

The binding snapshots its input. `toJsonC` returns a new snapshot, preserving
metadata, unbound columns, other rows, and unchanged cells. Each call starts
from the binding's original snapshot; create a new binding from the latest
saved JSONC when subsequent saves must include changes made elsewhere. The
constructor rejects invalid metadata, schema or row shape, a missing row,
invalid bound values, and missing, duplicate, or unknown column bindings. A save
must include exactly the bound fields; invalid or unrepresentable edits throw
`ArgumentError` so the host can report a save failure.

For edited numeric decimals, use a numeric-string `jnf` mode (0, 4, or 5).
Decimal input is validated by jcore, including its precision and scale rules.
In numeric modes, edited numeric values must be integers within the exact
portable range (±9007199254740991). On native Dart, raw INT64 values support
the full signed 64-bit range; use a BigInt-string mode (0, 3, or 5) when values
must also be safe for JavaScript. In those modes, jcore uses Dart `BigInt` values for INT64 cells
and serializes them as strings. Int32, datetime, and time use integer
representations. Unchanged cells keep their original representation and do not
undergo an edit conversion.

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
