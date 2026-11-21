import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mjux/mjux.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Consumer Asset Loading', () {
    test('reads fixture JSON with package prefix (as dependency)', () async {
      // Simulate how a consuming app would read MJUX's bundled assets
      final jsonString = await rootBundle.loadString(
        'packages/mjux/example/fixtures/storage_profiles_view.json',
      );

      expect(jsonString, isNotEmpty);
      expect(jsonString, contains('"uix": 1000'));
    });

    test('StorageProfilesFixture.load() works when MJUX is a dependency', () async {
      // This should work with the fixed _loadJson that tries both paths
      final fixture = await StorageProfilesFixture.load();

      expect(fixture.workspace.key, 'storage_profiles_workspace');
      expect(fixture.fullView.uix.i, 1000);
      expect(fixture.collection.uix.i, 10000);
      expect(fixture.inspection.uix.i, 20000);
      expect(fixture.form.uix.i, 30000);
    });

    test('fixture validates complete definition graph', () async {
      final fixture = await StorageProfilesFixture.load();

      // Verify the registry contains all expected definitions
      expect(fixture.registry.containsKey('storage_profiles_workspace'), isTrue);
      expect(fixture.registry.containsKey('storage_profiles_view'), isTrue);
      expect(fixture.registry.containsKey('storage_profile_collection'), isTrue);
      expect(fixture.registry.containsKey('storage_profile_inspection'), isTrue);
      expect(fixture.registry.containsKey('storage_profile_form'), isTrue);

      // Verify data and schema are loaded
      expect(fixture.data, isNotEmpty);
      expect(fixture.schema, isNotEmpty);
    });
  });
}
