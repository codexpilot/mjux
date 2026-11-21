import 'package:flutter_test/flutter_test.dart';
import 'package:jcore/jux.dart' as jux;
import 'package:mjux/mjux.dart';

void main() {
  group('MJUX Workspace Integration', () {
    test('catalog is valid', () {
      final errors = jux.validateCatalog();
      expect(errors, isEmpty, reason: errors.join('; '));
    });

    test('desk workspace renders with navigation rail', () async {
      final workspace = jux.WorkspaceDef(
        key: 'test_workspace',
        schemaVersion: 1,
        uix: jux.UIX.deskWorkspace,
        title: 'Test Workspace',
        destinations: const [
          jux.DestinationDef(id: 'home', label: 'Home', viewKey: 'home_view'),
          jux.DestinationDef(id: 'data', label: 'Data', viewKey: 'data_view'),
        ],
        initialDestination: 'home',
      );

      expect(workspace.validate(), isEmpty);
      expect(workspace.destinations.length, 2);
      expect(workspace.initialDestination, 'home');
    });

    test('mobile workspace configuration validates', () {
      final workspace = jux.WorkspaceDef(
        key: 'mobile_workspace',
        schemaVersion: 1,
        uix: jux.UIX.mobileWorkspace,
        title: 'Mobile Workspace',
        destinations: const [
          jux.DestinationDef(id: 'home', label: 'Home', viewKey: 'home_view'),
          jux.DestinationDef(id: 'data', label: 'Data', viewKey: 'data_view'),
          jux.DestinationDef(id: 'account', label: 'Account', viewKey: 'account_view'),
        ],
        initialDestination: 'home',
      );

      expect(workspace.validate(), isEmpty);
    });

    test('panel builders are registered', () {
      registerDefaultBuilders();

      expect(
        PanelBuilderRegistry.get(jux.UIX.collectionPanel.i),
        isNotNull,
      );
      expect(
        PanelBuilderRegistry.get(jux.UIX.inspectionPanel.i),
        isNotNull,
      );
      expect(
        PanelBuilderRegistry.get(jux.UIX.formPanel.i),
        isNotNull,
      );
    });

    test('full view definition validates placement', () {
      final fullView = jux.FullViewDef(
        key: 'storage_profiles_view',
        schemaVersion: 1,
        uix: jux.UIX.recordWorkspace,
        title: 'Storage Profiles',
        supportedWorkspaces: [jux.UIX.deskWorkspace.i, jux.UIX.mobileWorkspace.i],
        viewModelBinding: 'composed',
        panels: const jux.PanelComposition(
          desktop: jux.DesktopPanels(
            left: 'collection_panel',
            center: 'inspection_panel',
            right: 'form_panel',
          ),
          mobile: jux.MobilePanels(
            startingPanel: 'collection_panel',
            transitions: {
              'select': 'inspection_panel',
              'edit': 'form_panel',
            },
          ),
        ),
      );

      expect(fullView.validate(), isEmpty);
      expect(fullView.supportedWorkspaces.length, 2);
    });

    test('partial view definition validates fields and commands', () {
      final partialView = jux.PartialViewDef(
        key: 'storage_profile_form',
        schemaVersion: 1,
        uix: jux.UIX.formPanel,
        title: 'Storage Profile Form',
        dataSchemaRef: 'storage_profile',
        fields: const [
          jux.FieldBinding(
            key: 'name',
            label: 'Name',
            control: 'text',
            readOnly: false,
          ),
          jux.FieldBinding(
            key: 'ttx',
            label: 'Type',
            control: 'select',
            readOnly: false,
          ),
        ],
        commands: const [
          jux.CommandDef(command: 'save', label: 'Save', operation: 2001),
          jux.CommandDef(command: 'cancel', label: 'Cancel'),
        ],
      );

      expect(partialView.validate(), isEmpty);
      expect(partialView.fields.length, 2);
      expect(partialView.commands.length, 2);
    });
  });
}