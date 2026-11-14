import 'package:material_ui/material_ui.dart';
import 'package:mjux/mjux.dart';

void main() => runApp(const InventoryApp());

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garden inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff38605b)),
        scaffoldBackgroundColor: const Color(0xfff4f7f5),
      ),
      home: const _InventoryPage(),
    );
  }
}

typedef _Plant = ({String name, String category});

class _InventoryPage extends StatefulWidget {
  const _InventoryPage();

  @override
  State<_InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<_InventoryPage> {
  final _name = FieldKey();
  final _category = FieldKey();
  final _records = <_Plant>[
    (name: 'Basil', category: 'Herbs'),
    (name: 'Calendula', category: 'Flowers'),
  ];
  late final List<Surface> _surfaces;

  @override
  void initState() {
    super.initState();
    final utility = Utility();
    final editor = FormEditor1(
      title: 'Plant details',
      fields: [
        TextFieldSpec(key: _name, label: 'Plant name', isRequired: true),
        ChoiceFieldSpec(
          key: _category,
          label: 'Category',
          options: const ['Herbs', 'Flowers', 'Vegetables'],
          isRequired: true,
        ),
      ],
    );

    _surfaces = [
      for (var index = 0; index < _records.length; index++)
        utility.open(
          editor,
          initialValues: {
            _name: _records[index].name,
            _category: _records[index].category,
          },
          onSave: (request) => _save(index, request),
        ),
    ];
  }

  Future<SaveResult> _save(int index, SaveRequested request) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return const SaveFailed('The inventory is closed.');

    final name = request.values[_name] ?? '';
    final category = request.values[_category] ?? '';
    final other = _records[1 - index];
    if (name.trim().toLowerCase() == other.name.trim().toLowerCase()) {
      return const SaveFailed('A plant with that name already exists.');
    }

    setState(() => _records[index] = (name: name, category: category));
    return const SaveSucceeded();
  }

  @override
  void dispose() {
    for (final surface in _surfaces) {
      surface.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Garden inventory', style: textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Edit and save each record independently.',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 24.0;
                      final width = constraints.maxWidth;
                      final cardWidth = width >= 650
                          ? (width - gap) / 2
                          : width;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          for (var index = 0; index < _records.length; index++)
                            SizedBox(
                              key: ValueKey(index),
                              width: cardWidth,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Record ${index + 1}',
                                    style: textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Saved: ${_records[index].name} · '
                                    '${_records[index].category}',
                                  ),
                                  const SizedBox(height: 12),
                                  SurfaceView(surface: _surfaces[index]),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
