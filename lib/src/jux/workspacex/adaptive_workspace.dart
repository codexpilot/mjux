/// Adaptive workspace that switches between desktop and mobile layouts.
library;

import 'package:material_ui/material_ui.dart';
import 'package:jcore/jux.dart' as jux;
import '../panelx/panel_builders.dart';

/// Breakpoint for desktop vs mobile layout (pixels).
const double kDesktopBreakpoint = 768.0;

/// Adaptive workspace that renders desktop or mobile layout based on screen size.
///
/// Features:
/// - Automatic layout switching at breakpoint
/// - Single shared view model preserved across resize
/// - Selection, draft, and panel history maintained
/// - Command binding through panel builders
/// - Back button consumes panel history first
///
/// Usage:
/// ```dart
/// final registry = {
///   'collection': collectionPanelDef,
///   'inspection': inspectionPanelDef,
///   'form': formPanelDef,
/// };
///
/// AdaptiveWorkspace(
///   workspace: workspaceDef,
///   fullView: fullViewDef,
///   viewModel: composedViewModel,
///   panelRegistry: registry,
/// )
/// ```
class AdaptiveWorkspace extends StatefulWidget {
  const AdaptiveWorkspace({
    super.key,
    required this.workspace,
    required this.fullView,
    required this.viewModel,
    required this.panelRegistry,
    this.onBack,
  });

  final jux.WorkspaceDef workspace;
  final jux.SurfaceDef fullView;
  final jux.ComposedViewModel viewModel;
  final Map<String, jux.PanelDef> panelRegistry;
  final VoidCallback? onBack;

  @override
  State<AdaptiveWorkspace> createState() => _AdaptiveWorkspaceState();
}

class _AdaptiveWorkspaceState extends State<AdaptiveWorkspace> {
  late String _activeDestination;
  final List<String> _panelHistory = [];
  final List<String> _destinationHistory = [];

  @override
  void initState() {
    super.initState();
    _activeDestination = widget.workspace.initialDestination;
    _destinationHistory.add(_activeDestination);

    // Set initial panel from mobile composition
    final panels = widget.fullView.panels;
    if (panels != null) {
      widget.viewModel.setActivePanel(panels.mobile.startingPanel);
      _panelHistory.add(panels.mobile.startingPanel);
    }

    // Listen to view model changes
    widget.viewModel.addListener(_onViewModelChanged);

    // Load initial data
    widget.viewModel.load();
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

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= kDesktopBreakpoint;
  }

  /// Shows confirmation dialog if there are unsaved changes.
  /// Returns true if navigation should proceed (no changes or user confirmed discard).
  Future<bool> _confirmDiscardChanges() async {
    if (!widget.viewModel.hasUnsavedChanges) {
      return true; // No changes, proceed
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('You have unsaved changes. Discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _handleDestinationSelected(String destinationId) async {
    // Guard against navigation with unsaved changes
    if (!await _confirmDiscardChanges()) {
      return; // User cancelled
    }

    // Look up the destination
    final destination = widget.workspace.destinations.firstWhere(
      (d) => d.id == destinationId,
      orElse: () => throw StateError('Destination $destinationId not found'),
    );

    // Verify the destination's viewKey matches the current fullView
    if (destination.viewKey != widget.fullView.key) {
      // This would require loading a different surface
      // For now, log a warning since the current API only supports one surface
      debugPrint(
        'Warning: Destination ${destination.id} references view ${destination.viewKey} '
        'but AdaptiveWorkspace is displaying ${widget.fullView.key}',
      );
    }

    setState(() {
      _activeDestination = destinationId;
      _destinationHistory.add(destinationId);

      // Discard any draft when switching destinations
      if (widget.viewModel.hasUnsavedChanges) {
        widget.viewModel.cancelEdit();
      }

      // Reset to initial panel
      final panels = widget.fullView.panels;
      if (panels != null) {
        final initialPanel = panels.mobile.startingPanel;
        widget.viewModel.setActivePanel(initialPanel);
        _panelHistory.clear();
        _panelHistory.add(initialPanel);
      }
    });
  }

  void _handlePanelTransition(String command) async {
    // Guard against navigation with unsaved changes
    if (!await _confirmDiscardChanges()) {
      return; // User cancelled
    }

    final panels = widget.fullView.panels;
    if (panels == null) return;

    final nextPanel = panels.mobile.transitions[command];
    if (nextPanel != null) {
      setState(() {
        // Discard draft when transitioning
        if (widget.viewModel.hasUnsavedChanges) {
          widget.viewModel.cancelEdit();
        }

        widget.viewModel.setActivePanel(nextPanel);
        _panelHistory.add(nextPanel);
      });
    }
  }

  Future<bool> _handleBackButton() async {
    // Guard against navigation with unsaved changes
    if (!await _confirmDiscardChanges()) {
      return true; // Consumed - user cancelled
    }

    // Back consumes panel history first
    if (_panelHistory.length > 1) {
      setState(() {
        _panelHistory.removeLast();
        final previousPanel = _panelHistory.last;
        widget.viewModel.setActivePanel(previousPanel);
      });
      return true; // Consumed
    }

    // Then consume destination history
    if (_destinationHistory.length > 1) {
      setState(() {
        _destinationHistory.removeLast();
        final previousDestination = _destinationHistory.last;
        _activeDestination = previousDestination;

        // Reset to initial panel of destination
        final panels = widget.fullView.panels;
        if (panels != null) {
          final initialPanel = panels.mobile.startingPanel;
          widget.viewModel.setActivePanel(initialPanel);
          _panelHistory.clear();
          _panelHistory.add(initialPanel);
        }
      });
      return true; // Consumed
    }

    // No history - delegate to parent
    if (widget.onBack != null) {
      widget.onBack!();
      return true;
    }

    return false; // Not consumed - allow system back
  }

  Widget _buildPanel(BuildContext context, String panelKey) {
    final viewDef = widget.panelRegistry[panelKey];
    if (viewDef == null) {
      return Center(child: Text('Panel "$panelKey" not found'));
    }

    // Build panel with command callbacks bound
    final uixType = viewDef.uix;

    if (uixType == jux.UIX.collectionPanel) {
      return buildCollectionPanel(
        context,
        viewDef,
        widget.viewModel,
        onRefresh: () => widget.viewModel.load(),
        onSelectRow: (record) {
          widget.viewModel.selectRecord(record);
          _handlePanelTransition('select_row');
        },
        onCreate: () {
          // Create new record logic would go here
        },
      );
    } else if (uixType == jux.UIX.inspectionPanel) {
      return buildInspectionPanel(
        context,
        viewDef,
        widget.viewModel,
        onEdit: () {
          widget.viewModel.startEdit();
          _handlePanelTransition('edit');
        },
        onBack: () async => await _handleBackButton(),
      );
    } else if (uixType == jux.UIX.formPanel) {
      return buildFormPanel(
        context,
        viewDef,
        widget.viewModel,
        onSave: () async {
          try {
            await widget.viewModel.saveDraft(2001);
            if (mounted) {
              await _handleBackButton();
            }
          } catch (e) {
            // Error is already set in view model, no need to show snackbar
          }
        },
        onCancel: () async {
          widget.viewModel.cancelEdit();
          await _handleBackButton();
        },
        onBack: () async => await _handleBackButton(),
      );
    }

    // Fallback to registry builder
    return PanelBuilderRegistry.build(context, viewDef, widget.viewModel);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop(context);
    final panels = widget.fullView.panels;

    if (panels == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.workspace.title)),
        body: const Center(child: Text('No panels configured')),
      );
    }

    return PopScope(
      canPop: _panelHistory.length <= 1 && _destinationHistory.length <= 1,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleBackButton();
        }
      },
      child: isDesktop
          ? _buildDesktop(context, panels)
          : _buildMobile(context, panels),
    );
  }

  Widget _buildDesktop(BuildContext context, jux.PanelComposition panels) {
    return Scaffold(
      body: Row(
        children: [
          // Navigation rail
          NavigationRail(
            selectedIndex: widget.workspace.destinations
                .indexWhere((d) => d.id == _activeDestination),
            onDestinationSelected: (index) {
              _handleDestinationSelected(
                  widget.workspace.destinations[index].id);
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final dest in widget.workspace.destinations)
                NavigationRailDestination(
                  icon: const Icon(Icons.view_list),
                  label: Text(dest.label),
                ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Three-column panel layout
          Expanded(
            child: Row(
              children: [
                if (panels.desktop.left != null)
                  Expanded(
                    child: _buildPanel(context, panels.desktop.left!),
                  ),
                if (panels.desktop.left != null &&
                    panels.desktop.center != null)
                  const VerticalDivider(thickness: 1, width: 1),
                if (panels.desktop.center != null)
                  Expanded(
                    child: _buildPanel(context, panels.desktop.center!),
                  ),
                if (panels.desktop.center != null &&
                    panels.desktop.right != null)
                  const VerticalDivider(thickness: 1, width: 1),
                if (panels.desktop.right != null)
                  Expanded(
                    child: _buildPanel(context, panels.desktop.right!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context, jux.PanelComposition panels) {
    final activePanel = widget.viewModel.activePanel ?? panels.mobile.startingPanel;
    final hasHistory = _panelHistory.length > 1 || _destinationHistory.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workspace.title),
        leading: hasHistory
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async => await _handleBackButton(),
              )
            : null,
      ),
      body: _buildPanel(context, activePanel),
      bottomNavigationBar: _buildBottomBar(),
      drawer: _buildDrawer(),
    );
  }

  Widget? _buildBottomBar() {
    final primaryDestIds = widget.workspace.primaryDestinations ??
        widget.workspace.destinations.map((d) => d.id).toList();

    // Only show bottom bar if we have 2-5 destinations
    if (primaryDestIds.length < 2 || primaryDestIds.length > 5) {
      return null;
    }

    final bottomBarDests = widget.workspace.destinations
        .where((d) => primaryDestIds.contains(d.id))
        .toList();

    final selectedIndex = bottomBarDests.indexWhere((d) => d.id == _activeDestination);

    return NavigationBar(
      selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
      onDestinationSelected: (index) {
        _handleDestinationSelected(bottomBarDests[index].id);
      },
      destinations: [
        for (final dest in bottomBarDests)
          NavigationDestination(
            icon: const Icon(Icons.view_list),
            label: dest.label,
          ),
      ],
    );
  }

  Widget? _buildDrawer() {
    // Show drawer when there are >5 destinations or <2 (can't use bottom bar)
    final primaryDestIds = widget.workspace.primaryDestinations ??
        widget.workspace.destinations.map((d) => d.id).toList();

    if (primaryDestIds.length >= 2 && primaryDestIds.length <= 5) {
      return null; // Bottom bar handles this case
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Text(
              widget.workspace.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          for (final dest in widget.workspace.destinations)
            ListTile(
              leading: const Icon(Icons.view_list),
              title: Text(dest.label),
              selected: dest.id == _activeDestination,
              onTap: () {
                Navigator.of(context).pop(); // Close drawer
                _handleDestinationSelected(dest.id);
              },
            ),
        ],
      ),
    );
  }
}
