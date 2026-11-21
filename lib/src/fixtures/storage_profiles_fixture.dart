/// Fixture loader for Storage Profiles demonstration.
library;

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:jcore/jux.dart' as jux;
import 'package:jcore/data.dart' as jdata;

/// Loads the complete Storage Profiles fixture from JSON files.
class StorageProfilesFixture {
  const StorageProfilesFixture._({
    required this.workspace,
    required this.fullView,
    required this.collection,
    required this.inspection,
    required this.form,
    required this.schema,
    required this.data,
    required this.registry,
  });

  final jux.WorkspaceDef workspace;
  final jux.SurfaceDef fullView;
  final jux.PanelDef collection;
  final jux.PanelDef inspection;
  final jux.PanelDef form;
  final Map<String, dynamic> schema;
  final List<Map<String, dynamic>> data;
  final Map<String, jux.UIDef> registry;

  static Future<StorageProfilesFixture> load() async {
    final workspaceJson = await _loadJson('example/fixtures/storage_profiles_workspace.json');
    final fullViewJson = await _loadJson('example/fixtures/storage_profiles_view.json');
    final collectionJson = await _loadJson('example/fixtures/storage_profile_collection.json');
    final inspectionJson = await _loadJson('example/fixtures/storage_profile_inspection.json');
    final formJson = await _loadJson('example/fixtures/storage_profile_form.json');
    final schemaJson = await _loadJson('example/fixtures/storage_profile_schema.json');
    final dataJson = await _loadJson('example/fixtures/storage_profile_data.json');

    final workspace = jux.WorkspaceDef.fromJson(workspaceJson);
    final fullView = jux.SurfaceDef.fromJson(fullViewJson);
    final collection = jux.PanelDef.fromJson(collectionJson);
    final inspection = jux.PanelDef.fromJson(inspectionJson);
    final form = jux.PanelDef.fromJson(formJson);

    final registry = <String, jux.UIDef>{
      workspace.key: workspace,
      fullView.key: fullView,
      collection.key: collection,
      inspection.key: inspection,
      form.key: form,
    };

    // Validate the complete graph
    final errors = <String>[];
    for (final def in registry.values) {
      errors.addAll(def.validate(registry));
    }
    if (errors.isNotEmpty) {
      throw FormatException('Fixture validation failed: ${errors.join('; ')}');
    }

    return StorageProfilesFixture._(
      workspace: workspace,
      fullView: fullView,
      collection: collection,
      inspection: inspection,
      form: form,
      schema: schemaJson,
      data: (dataJson['records'] as List).cast<Map<String, dynamic>>(),
      registry: registry,
    );
  }

  static Future<Map<String, dynamic>> _loadJson(String path) async {
    final content = await rootBundle.loadString(path);
    return jsonDecode(content) as Map<String, dynamic>;
  }
}

/// Mock QueryService for fixture data.
class FixtureQueryService implements jdata.QueryService {
  FixtureQueryService(this.data);

  final List<Map<String, dynamic>> data;

  @override
  Future<dynamic> executeQuery(int queryId, Map<String, dynamic> params) async {
    // Simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 100));

    switch (queryId) {
      case 2000: // List operation
        return List<Map<String, dynamic>>.from(data);
      case 2001: // Save operation
        final id = params['i'] as int?;
        if (id == null) {
          // Create new
          final newId = data.isEmpty ? 1 : data.map((r) => r['i'] as int).reduce((a, b) => a > b ? a : b) + 1;
          final newRecord = Map<String, dynamic>.from(params);
          newRecord['i'] = newId;
          data.add(newRecord);
          return newRecord;
        } else {
          // Update existing
          final index = data.indexWhere((r) => r['i'] == id);
          if (index >= 0) {
            data[index] = Map<String, dynamic>.from(params);
            return data[index];
          }
          throw Exception('Record not found: $id');
        }
      case 2002: // Get operation
        final id = params['i'] as int;
        final record = data.firstWhere((r) => r['i'] == id,
            orElse: () => throw Exception('Record not found: $id'));
        return record;
      default:
        throw Exception('Unknown query ID: $queryId');
    }
  }
}
