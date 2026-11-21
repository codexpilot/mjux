/// Adaptive workspace that switches between desktop and mobile layouts.
library;

import 'package:material_ui/material_ui.dart';
import 'package:jcore/jux.dart' as jux;
import '../builders/panel_builders.dart';

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
  final jux.FullViewDef fullView;
  final jux.ComposedViewModel viewModel;
  final Map<String, jux.PartialViewDef> panelRegistry;
  final VoidCallback? onBack;

  @override
  State<AdaptiveWorkspace> createState() => _AdaptiveWorkspaceState();
}

class _AdaptiveWorkspaceState extends State<AdaptiveWorkspace> {
  late String _activeDestination;
  final List<String> _panelHistory = [];

  @override
  void initState() {
    super.initState();
    _activeDestination = widget.workspace.initialDestination;

    // Set initial panel from mobile composition
    final panels = widget.fullView.panels;
    if (panels != null) {
      widget.viewModel.setActivePanel(panels.mobile.startingPanel);
      _panelHistory.add(panels.mobile.startingPanel);
    }

    // Load initial data
    widget.viewModel.load();
  }

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= kDesktopBreakpoint;
  }

  void _handleDestinationSelected(String destinationId) {
    setState(() {
      _activeDestination = destinationId;
    });
  }

  void _handlePanelTransition(String command) {
    final panels = widget.fullView.panels;
    if (panels == null) return;

    final nextPanel = panels.mobile.transitions[command];
    if (nextPanel != null) {
      setState(() {
        widget.viewModel.setActivePanel(nextPanel);
        _panelHistory.add(nextPanel);
      });
    }
  }

  bool _handleBackButton() {
    // Back consumes panel history first
    if (_panelHistory.length > 1) {
      setState(() {
        _panelHistory.removeLast();
        final previousPanel = _panelHistory.last;
        widget.viewModel.setActivePanel(previousPanel);
      });
      return true; // Consumed
    }

    // No panel history - delegate to parent
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
        onBack: () => _handleBackButton(),
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
              _handleBackButton();
            }
          } catch (e) {
            // Error is already set in view model, no need to show snackbar
          }
        },
        onCancel: () {
          widget.viewModel.cancelEdit();
          _handleBackButton();
        },
        onBack: () => _handleBackButton(),
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
      canPop: !_handleBackButton(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackButton();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workspace.title),
        leading: _panelHistory.length > 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleBackButton(),
              )
            : null,
      ),
      body: _buildPanel(context, activePanel),
      bottomNavigationBar: _buildBottomBar(),
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
}
