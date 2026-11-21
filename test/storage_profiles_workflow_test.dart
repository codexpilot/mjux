import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:jcore/jux.dart' as jux;
import 'package:jcore/data.dart' as jdata;
import 'package:mjux/mjux.dart';

/// Test helper widget that rebuilds when view model notifies listeners.
class _ViewModelListener extends StatefulWidget {
  const _ViewModelListener({
    required this.viewModel,
    required this.builder,
  });

  final jux.ViewModel viewModel;
  final Widget Function(BuildContext) builder;

  @override
  State<_ViewModelListener> createState() => _ViewModelListenerState();
}

class _ViewModelListenerState extends State<_ViewModelListener> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

void main() {
  group('Storage Profiles Workflow', () {
    late List<Map<String, dynamic>> testData;
    late jdata.QueryService queryService;
    late jux.WorkspaceDef workspace;
    late jux.SurfaceDef fullView;
    late jux.PanelDef collection;
    late jux.PanelDef inspection;
    late jux.PanelDef form;
    late Map<String, jux.UIDef> registry;

    setUp(() {
      testData = [
        {'i': 1, 'name': 'Profile 1', 'ttx': 1},
        {'i': 2, 'name': 'Profile 2', 'ttx': 2},
      ];

      queryService = _MockQueryService(testData);

      collection = jux.PanelDef(
        key: 'storage_profile_collection',
        schemaVersion: 1,
        uix: jux.UIX.collectionPanel,
        title: 'Collection',
        dataSchemaRef: 'storage_profile',
        fields: const [
          jux.FieldBinding(key: 'i', label: 'ID', control: 'display', readOnly: true),
          jux.FieldBinding(key: 'name', label: 'Name', control: 'text', readOnly: true),
        ],
        commands: const [
          jux.CommandDef(command: 'refresh', label: 'Refresh', operation: 2000),
          jux.CommandDef(command: 'select_row', label: 'Select'),
        ],
      );

      inspection = jux.PartialViewDef(
        key: 'storage_profile_inspection',
        schemaVersion: 1,
        uix: jux.UIX.inspectionPanel,
        title: 'Details',
        dataSchemaRef: 'storage_profile',
        fields: const [
          jux.FieldBinding(key: 'i', label: 'ID', control: 'display', readOnly: true),
          jux.FieldBinding(key: 'name', label: 'Name', control: 'text', readOnly: true),
          jux.FieldBinding(key: 'ttx', label: 'Type', control: 'select', readOnly: true),
        ],
        commands: const [
          jux.CommandDef(command: 'edit', label: 'Edit'),
          jux.CommandDef(command: 'back', label: 'Back'),
        ],
      );

      form = jux.PartialViewDef(
        key: 'storage_profile_form',
        schemaVersion: 1,
        uix: jux.UIX.formPanel,
        title: 'Edit Profile',
        dataSchemaRef: 'storage_profile',
        fields: const [
          jux.FieldBinding(key: 'i', label: 'ID', control: 'display', readOnly: true),
          jux.FieldBinding(key: 'name', label: 'Name', control: 'text', readOnly: false),
          jux.FieldBinding(key: 'ttx', label: 'Type', control: 'select', readOnly: false),
        ],
        commands: const [
          jux.CommandDef(command: 'save', label: 'Save', operation: 2001),
          jux.CommandDef(command: 'cancel', label: 'Cancel'),
        ],
      );

      fullView = jux.SurfaceDef(
        key: 'storage_profiles_view',
        schemaVersion: 1,
        uix: jux.UIX.recordSurface,
        title: 'Storage Profiles',
        supportedWorkspaces: [jux.UIX.deskWorkspace.i, jux.UIX.mobileWorkspace.i],
        viewModelBinding: 'composed',
        panels: const jux.PanelComposition(
          desktop: jux.DesktopPanels(
            left: 'storage_profile_collection',
            center: 'storage_profile_inspection',
            right: 'storage_profile_form',
          ),
          mobile: jux.MobilePanels(
            startingPanel: 'storage_profile_collection',
            transitions: {
              'select_row': 'storage_profile_inspection',
              'edit': 'storage_profile_form',
            },
          ),
        ),
      );

      workspace = jux.WorkspaceDef(
        key: 'storage_profiles_workspace',
        schemaVersion: 1,
        uix: jux.UIX.deskWorkspace,
        title: 'Storage Profiles',
        destinations: const [
          jux.DestinationDef(id: 'profiles', label: 'Profiles', viewKey: 'storage_profiles_view'),
          jux.DestinationDef(id: 'settings', label: 'Settings', viewKey: 'storage_profiles_view'),
        ],
        primaryDestinations: const ['profiles'],
        initialDestination: 'profiles',
      );

      registry = {
        'storage_profile_collection': collection,
        'storage_profile_inspection': inspection,
        'storage_profile_form': form,
        'storage_profiles_view': fullView,
        'storage_profiles_workspace': workspace,
      };

      registerDefaultBuilders();
    });

    testWidgets('validates complete definition graph', (tester) async {
      for (final def in registry.values) {
        final errors = def.validate(registry);
        expect(errors, isEmpty, reason: 'Definition ${def.key} has errors: ${errors.join("; ")}');
      }
    });

    testWidgets('loads and displays collection data', (tester) async {
      final vm = jux.ComposedViewModel(
        queryService: queryService,
        fullView: fullView,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => _ViewModelListener(
                viewModel: vm,
                builder: (context) => buildCollectionPanel(
                  context,
                  collection,
                  vm,
                  onRefresh: () => vm.load(listOperationId: 2000),
                ),
              ),
            ),
          ),
        ),
      );

      // Initial state - no records
      expect(find.text('No records'), findsOneWidget);

      // Load data
      vm.load(listOperationId: 2000);
      await tester.pump(); // Start async operation
      await tester.pump(const Duration(milliseconds: 20)); // Wait for mock delay
      await tester.pumpAndSettle(); // Complete all pending operations

      // Should show records
      expect(find.text('Profile 1'), findsOneWidget);
      expect(find.text('Profile 2'), findsOneWidget);
    });

    testWidgets('selects record and shows in inspection panel', (tester) async {
      final vm = jux.ComposedViewModel(
        queryService: queryService,
        fullView: fullView,
      );

      // Load data first
      vm.load(listOperationId: 2000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => _ViewModelListener(
                viewModel: vm,
                builder: (context) => buildInspectionPanel(
                  context,
                  inspection,
                  vm,
                ),
              ),
            ),
          ),
        ),
      );

      // Initially no selection
      expect(find.text('No record selected'), findsOneWidget);

      // Select a record
      vm.selectRecord(testData[0]);
      await tester.pumpAndSettle();

      // Should show selected data
      expect(find.text('Profile 1'), findsOneWidget);
      expect(find.text('1'), findsAtLeastNWidgets(1)); // ID field
    });

    testWidgets('edits record in form and saves', (tester) async {
      final vm = jux.ComposedViewModel(
        queryService: queryService,
        fullView: fullView,
      );

      // Load and setup
      vm.load(listOperationId: 2000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      vm.selectRecord(testData[0]);
      vm.startEdit();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => _ViewModelListener(
                viewModel: vm,
                builder: (context) => buildFormPanel(
                  context,
                  form,
                  vm,
                  onSave: () async {
                    await vm.saveDraft(2001);
                  },
                  onCancel: () {
                    vm.cancelEdit();
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Should show draft
      expect(vm.hasUnsavedChanges, isTrue);
      expect(find.text('Profile 1'), findsOneWidget);

      // Edit field
      await tester.enterText(find.byType(TextFormField).at(1), 'Modified Profile');
      await tester.pump();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpAndSettle();

      // Should update
      expect(vm.hasUnsavedChanges, isFalse);
      expect(vm.selectedRecord!['name'], 'Modified Profile');
    });

    test('handles failed save with retry', () async {
      var failCount = 0;
      final failingService = _FailingQueryService(testData, () {
        failCount++;
        return failCount == 1; // Fail first time, succeed second time
      });

      final vm = jux.ComposedViewModel(
        queryService: failingService,
        fullView: fullView,
      );

      await vm.load(listOperationId: 2000);
      vm.selectRecord(testData[0]);
      vm.startEdit();
      vm.updateDraft('name', 'Modified');

      // First save attempt fails
      await expectLater(vm.saveDraft(2001), throwsException);
      expect(vm.hasError, isTrue);
      expect(vm.hasUnsavedChanges, isTrue);

      // Retry succeeds
      await vm.saveDraft(2001);
      expect(vm.hasUnsavedChanges, isFalse);
      expect(failCount, 2);
    });

    test('prevents duplicate saves', () async {
      final vm = jux.ComposedViewModel(
        queryService: queryService,
        fullView: fullView,
      );

      await vm.load(listOperationId: 2000);
      vm.selectRecord(testData[0]);
      vm.startEdit();
      vm.updateDraft('name', 'Modified');

      // Start first save
      final save1 = vm.saveDraft(2001);

      // Second save while first is pending should throw
      expect(() => vm.saveDraft(2001), throwsStateError);

      await save1;
    });

    testWidgets('mobile workspace renders with one destination', (tester) async {
      final singleDestWorkspace = jux.WorkspaceDef(
        key: 'single_dest',
        schemaVersion: 1,
        uix: jux.UIX.mobileWorkspace,
        title: 'Test',
        destinations: const [
          jux.DestinationDef(id: 'home', label: 'Home', viewKey: 'storage_profiles_view'),
        ],
        initialDestination: 'home',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MobileWorkspace(
            workspace: singleDestWorkspace,
            activeDestination: 'home',
            onDestinationSelected: (_) {},
            child: const Text('Content'),
          ),
        ),
      );

      // Should render without assertion
      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing); // Only 1 destination
    });
  });
}

class _MockQueryService implements jdata.QueryService {
  _MockQueryService(this.data);

  final List<Map<String, dynamic>> data;

  @override
  Future<dynamic> executeQuery(int queryId, Map<String, dynamic> params) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));

    switch (queryId) {
      case 2000: // List
        return List<Map<String, dynamic>>.from(data);
      case 2001: // Save
        final id = params['i'] as int;
        final index = data.indexWhere((r) => r['i'] == id);
        if (index >= 0) {
          data[index] = Map<String, dynamic>.from(params);
          return data[index];
        }
        throw Exception('Not found');
      default:
        throw Exception('Unknown operation: $queryId');
    }
  }
}

class _FailingQueryService implements jdata.QueryService {
  _FailingQueryService(this.data, this.shouldFail);

  final List<Map<String, dynamic>> data;
  final bool Function() shouldFail;

  @override
  Future<dynamic> executeQuery(int queryId, Map<String, dynamic> params) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));

    if (queryId == 2001 && shouldFail()) {
      throw Exception('Save failed');
    }

    switch (queryId) {
      case 2000:
        return List<Map<String, dynamic>>.from(data);
      case 2001:
        final id = params['i'] as int;
        final index = data.indexWhere((r) => r['i'] == id);
        if (index >= 0) {
          data[index] = Map<String, dynamic>.from(params);
          return data[index];
        }
        throw Exception('Not found');
      default:
        throw Exception('Unknown operation: $queryId');
    }
  }
}
