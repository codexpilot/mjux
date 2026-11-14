# Completed features

## Form editor prototype

MJUX `0.1.0` can open and render two instances of the same generic
`FormEditor1` Catalog item. Each surface has its own editable values,
required-field validation, and save status. The host decides how to persist
each save request and can return an error for the form to display.

The garden inventory example opens the same form definition for two records
with different starting values. Edit and save the first record to see its
saved summary change. Use the second record's name in the first form to see
the host reject the duplicate. The example keeps saved records in memory for
the lifetime of the app. [Example source](../../example/lib/main.dart)

The example imports the public MJUX library and supplies configuration and
save behavior. MJUX assembles the form internally using `material_ui`
controls registered in Core.

To run the native macOS example from the repository root, use the following commands.

```sh
cd example
flutter pub get
flutter run -d macos
```

Run `flutter test` in `example/` to exercise independent drafts, choice
selection, and host save success and rejection. Run `flutter test` in the
repository root to exercise required-field validation, edits during a pending
save, and disposal while the host is saving.
[Example test](../../example/test/inventory_test.dart) ·
[Package tests](../../test/form_surface_test.dart)

Static analysis reported no issues with `dart analyze --fatal-infos`. Both
package widget tests passed. The example widget test passed on the default
Flutter test runner and Chrome. The example also built with `flutter build web`.

The prototype covers local Dart use with text and choice fields. The working
plan tracks host refresh, additional Catalog items, platform coverage, and
optional protocol adapters. [Working plan](../plan/README.md) ·
[API reference](../api/README.md)
