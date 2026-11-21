/// DeskWorkspace - Desktop layout with navigation rail and panel composition.
library;

import 'package:material_ui/material_ui.dart';
import 'package:jcore/jux.dart' as jux;

/// Desktop workspace with left navigation rail and up to three panel slots.
///
/// - Navigation rail occupies its own column
/// - Full views can render in the content area or compose panels
/// - Panels use left, center, and right slots
class DeskWorkspace extends StatelessWidget {
  const DeskWorkspace({
    super.key,
    required this.workspace,
    required this.activeDestination,
    required this.onDestinationSelected,
    required this.child,
  });

  final jux.WorkspaceDef workspace;
  final String activeDestination;
  final ValueChanged<String> onDestinationSelected;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final destinations = workspace.destinations;
    final selectedIndex = destinations.indexWhere((d) => d.id == activeDestination);

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavigationRail(
            selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
            onDestinationSelected: (index) {
              onDestinationSelected(destinations[index].id);
            },
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final dest in destinations)
                NavigationRailDestination(
                  icon: const Icon(Icons.view_list),
                  label: Text(dest.label),
                ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Panel composition layout for desktop (left, center, right slots).
class DeskPanelLayout extends StatelessWidget {
  const DeskPanelLayout({
    super.key,
    this.left,
    this.center,
    this.right,
  });

  final Widget? left;
  final Widget? center;
  final Widget? right;

  @override
  Widget build(BuildContext context) {
    final panels = [
      if (left != null) Expanded(child: left!),
      if (center != null) Expanded(child: center!),
      if (right != null) Expanded(child: right!),
    ];

    if (panels.isEmpty) {
      return const Center(child: Text('No panels configured'));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: panels,
    );
  }
}
