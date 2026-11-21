# MJUX Package Consumer Handoff

## Summary

MJUX is now ready for consumption by ContextStudio and Dataset. All asset loading issues are resolved, and AdaptiveWorkspace provides complete navigation behaviors with dirty-draft guards.

## Completed Tasks

### Task 1: Fixed Consumer Asset Loading ✅

Modified `StorageProfilesFixture._loadJson()` to handle Flutter's package asset namespace. The loader now:
1. Tries package-prefixed path first: `packages/mjux/example/fixtures/...`
2. Falls back to bare path for standalone use: `example/fixtures/...`

**Verification:** Added `test/consumer_asset_loading_test.dart` with three passing tests:
- Direct JSON read with package prefix
- `StorageProfilesFixture.load()` from dependency context  
- Complete fixture validation

**Commit:** f7b42b6

### Task 2: Finished AdaptiveWorkspace Behaviors ✅

Enhanced `lib/src/jux/workspacex/adaptive_workspace.dart` with:

1. **Destination History Tracking**: Maintains navigation stack of destination changes alongside panel history

2. **Dirty-Draft Guard**: Shows confirmation dialog before all navigation when `viewModel.hasUnsavedChanges` is true
   - User can cancel (stay) or discard (proceed)
   - Guards: destination selection, panel transitions, back navigation

3. **Destination Resolution**: `_handleDestinationSelected()` now:
   - Checks for unsaved changes and prompts user
   - Looks up destination by ID
   - Verifies viewKey matches current fullView (logs warning if mismatch)
   - Cancels draft and resets to initial panel state
   - Adds to destination history

4. **Back Button Navigation**: Consumes history in order:
   - First: panel history (navigate between panels in current destination)
   - Second: destination history (navigate between destinations)
   - Finally: delegates to parent `onBack` callback

5. **Mobile Drawer Support**: Shows drawer instead of bottom bar when:
   - More than 5 destinations (bottom bar limit)
   - Less than 2 destinations (bottom bar requires 2+)

6. **State Retention**: View model is shared across desktop ↔ mobile resize, preserving:
   - Selected record
   - Draft changes
   - Panel and destination history

**Commit:** fc90afc

## JCore Dependency (Verified)

```yaml
jcore:
  git:
    url: https://github.com/codexpilot/jcore.git
    ref: main
    resolved-ref: d93c80fffc584cf7d37bdfeae1c29d659bbc269f
    path: dart
  version: 4.4.0
```

**Git SHA:** `d93c80fffc584cf7d37bdfeae1c29d659bbc269f`  
**Commit:** "fix(jux): prevent stale refresh from overwriting saved data"

This version includes the ComposedViewModel race condition fix using timestamp-based stale detection.

## MJUX Exported API

From `lib/mjux.dart`:

### Workspaces

```dart
// Adaptive workspace that switches between desktop and mobile layouts
class AdaptiveWorkspace extends StatefulWidget {
  const AdaptiveWorkspace({
    required this.workspace,        // jux.WorkspaceDef
    required this.fullView,         // jux.SurfaceDef
    required this.viewModel,        // jux.ComposedViewModel
    required this.panelRegistry,    // Map<String, jux.PanelDef>
    this.onBack,                    // VoidCallback?
  });
}

// Desktop-only workspace with navigation rail
class DeskWorkspace extends StatefulWidget { /* ... */ }

// Mobile-only workspace with bottom bar or drawer  
class MobileWorkspace extends StatefulWidget { /* ... */ }
```

### Panel Builders

```dart
// Build collection panel (list/grid of records)
Widget buildCollectionPanel(
  BuildContext context,
  jux.PanelDef viewDef,
  jux.ViewModel viewModel, {
  VoidCallback? onRefresh,
  void Function(Map<String, dynamic>)? onSelectRow,
  VoidCallback? onCreate,
});

// Build inspection panel (read-only record details)
Widget buildInspectionPanel(
  BuildContext context,
  jux.PanelDef viewDef,
  jux.ViewModel viewModel, {
  VoidCallback? onEdit,
  VoidCallback? onBack,
});

// Build form panel (editable record)
Widget buildFormPanel(
  BuildContext context,
  jux.PanelDef viewDef,
  jux.ViewModel viewModel, {
  Future<void> Function()? onSave,
  VoidCallback? onCancel,
  VoidCallback? onBack,
});

// Registry for custom panel builders
class PanelBuilderRegistry {
  static void register(jux.UIX uixType, PanelBuilder builder);
  static Widget build(BuildContext context, jux.UIDef def, jux.ViewModel vm);
}

// Register default builders (call once at app startup)
void registerDefaultBuilders();
```

### Fixtures

```dart
class StorageProfilesFixture {
  final jux.WorkspaceDef workspace;
  final jux.SurfaceDef fullView;
  final jux.PanelDef collection;
  final jux.PanelDef inspection;
  final jux.PanelDef form;
  final Map<String, dynamic> schema;
  final List<Map<String, dynamic>> data;
  final Map<String, jux.UIDef> registry;

  static Future<StorageProfilesFixture> load();
}

// Mock query service for fixture data
class FixtureQueryService implements jdata.QueryService {
  FixtureQueryService(List<Map<String, dynamic>> data);
  // Handles operations: 2000 (list), 2001 (save), 2002 (get)
}
```

### Form Integration

```dart
// JsonC form binding for JCore integration
class JsonCFormBinding { /* ... */ }
```

### Utilities

```dart
class Surface { /* ... */ }
class SurfaceView { /* ... */ }  
class Utility { /* ... */ }
```

## Test Results

**All 32 tests pass** (ran in ~10 seconds):

```
✓ Consumer Asset Loading (3 tests)
  - reads fixture JSON with package prefix (as dependency)
  - StorageProfilesFixture.load() works when MJUX is a dependency
  - fixture validates complete definition graph

✓ Storage Profiles Workflow (7 tests)
  - validates complete definition graph
  - loads and displays collection data
  - selects record and shows in inspection panel
  - edits record in form and saves
  - handles failed save with retry
  - prevents duplicate saves
  - mobile workspace renders with one destination

✓ Form Surface (8 tests)
✓ MJUX Integration (11 tests)
✓ JsonC Form Binding (3 tests)
```

**Flutter analyze:** No issues found

## Usage Example

```dart
import 'package:flutter/material.dart';
import 'package:mjux/mjux.dart';
import 'package:jcore/jux.dart' as jux;
import 'package:jcore/data.dart' as jdata;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FutureBuilder<StorageProfilesFixture>(
        future: StorageProfilesFixture.load(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final fixture = snapshot.data!;
          final viewModel = jux.ComposedViewModel(
            queryService: FixtureQueryService(fixture.data),
            fullView: fixture.fullView,
          );

          return AdaptiveWorkspace(
            workspace: fixture.workspace,
            fullView: fixture.fullView,
            viewModel: viewModel,
            panelRegistry: {
              fixture.collection.key: fixture.collection,
              fixture.inspection.key: fixture.inspection,
              fixture.form.key: fixture.form,
            },
          );
        },
      ),
    );
  }
}
```

## What Remains

### Not Yet Implemented

1. **Typed Field Control Hook**: No exported hook for ContextStudio's TypeX selector yet
   - Required for custom field type rendering
   - Should expose callback: `Widget Function(BuildContext, FieldDef, dynamic value, ValueChanged)`

2. **Operation Binding**: No helper to bind declared operations to QueryService with non-default IDs
   - Currently operations use hardcoded IDs (2000, 2001, 2002)
   - Should support: `viewModel.bindOperation('refresh', customQueryId)`

3. **Multi-Surface Support**: AdaptiveWorkspace accepts single `fullView` parameter
   - Works for fixtures where all destinations point to same surface
   - To support multiple surfaces per workspace, would need `Map<String, SurfaceDef>`
   - Currently logs warning if destination.viewKey doesn't match fullView.key

4. **Comprehensive Widget Tests**: AdaptiveWorkspace behaviors are implemented but lack dedicated tests
   - Manual testing confirmed: dirty-draft guard works, drawer appears, history navigation functions
   - Automated widget tests would verify: discard denial, discard confirmation, resize state retention

### Known Limitations

1. **Asset Path Requirements**: Consuming apps must include MJUX in their `pubspec.yaml` with Flutter's asset registration
   ```yaml
   flutter:
     assets:
       - packages/mjux/example/fixtures/
   ```

2. **Operation IDs**: FixtureQueryService uses fixed IDs (2000/2001/2002)
   - Real apps should use QueryService with their own operation catalog

3. **Panel Builder Customization**: Panel builders use Material UI components
   - Apps needing different UX must register custom builders via PanelBuilderRegistry

## Integration Checklist for ContextStudio/Dataset

- [ ] Add MJUX dependency to `pubspec.yaml`:
  ```yaml
  mjux:
    git:
      url: https://github.com/codexpilot/mjux.git
      ref: main
  ```

- [ ] Verify JCore dependency resolves to `d93c80fffc584cf7d37bdfeae1c29d659bbc269f` or later

- [ ] Call `registerDefaultBuilders()` once at app startup

- [ ] Build workspace, surface, and panel definitions using JCore JUX types

- [ ] Create ComposedViewModel with app's QueryService implementation

- [ ] Wrap in AdaptiveWorkspace or DeskWorkspace/MobileWorkspace

- [ ] Test on both desktop and mobile breakpoints

- [ ] Verify dirty-draft guard prompts appear when expected

- [ ] Test navigation: rail, bottom bar, drawer, back button

## Repository State

**Branch:** main  
**Latest Commits:**
- fc90afc - feat(workspacex): implement shared navigation history and dirty-draft guard
- f7b42b6 - fix: enable asset loading when MJUX is consumed as dependency
- 075577c - feat: migrate to GitHub dependencies (JCore)

**Clean Working Directory:** Yes  
**All Tests Passing:** Yes (32/32)  
**Flutter Analyze:** No issues

---

**Handoff Complete** — MJUX is ready for ContextStudio and Dataset integration.
