/// MobileWorkspace - Mobile layout with bottom navigation bar and drawer.
library;

import 'package:material_ui/material_ui.dart';
import 'package:jcore/jux.dart' as jux;

/// Mobile workspace with bottom bar, drawer, and single-panel display.
///
/// - Bottom navigation bar for primary destinations (up to 5)
/// - Drawer shows full navigation map
/// - One panel at a time with page/sheet transitions
/// - Preserves selection, draft, and panel history across navigation
class MobileWorkspace extends StatelessWidget {
  const MobileWorkspace({
    super.key,
    required this.workspace,
    required this.activeDestination,
    required this.onDestinationSelected,
    required this.child,
    this.drawer,
  });

  final jux.WorkspaceDef workspace;
  final String activeDestination;
  final ValueChanged<String> onDestinationSelected;
  final Widget child;
  final Widget? drawer;

  static const _maxBottomBarDestinations = 5;

  @override
  Widget build(BuildContext context) {
    final allDestinations = workspace.destinations;

    // Determine which destinations to show in bottom bar
    // Use primaryDestinations if specified, otherwise all destinations
    final bottomBarDestIds = workspace.primaryDestinations ??
        allDestinations.map((d) => d.id).toList();

    // Only show bottom bar if we have 2-5 destinations (Material requirement: >= 2)
    final showBottomBar = bottomBarDestIds.length >= 2 &&
        bottomBarDestIds.length <= _maxBottomBarDestinations;

    // Filter to bottom bar destinations
    final bottomBarDests = showBottomBar
        ? allDestinations.where((d) => bottomBarDestIds.contains(d.id)).toList()
        : <jux.DestinationDef>[];

    final selectedIndex = showBottomBar
        ? bottomBarDests.indexWhere((d) => d.id == activeDestination)
        : -1;

    return Scaffold(
      appBar: AppBar(
        title: Text(workspace.title),
        leading: showBottomBar ? null : Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Open navigation',
          ),
        ),
      ),
      drawer: drawer ?? _buildDefaultDrawer(allDestinations),
      body: child,
      bottomNavigationBar: showBottomBar
          ? NavigationBar(
              selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
              onDestinationSelected: (index) {
                onDestinationSelected(bottomBarDests[index].id);
              },
              destinations: [
                for (final dest in bottomBarDests)
                  NavigationDestination(
                    icon: const Icon(Icons.view_list),
                    label: dest.label,
                  ),
              ],
            )
          : null,
    );
  }

  Widget _buildDefaultDrawer(List<jux.DestinationDef> allDestinations) {
    final selectedIndex = allDestinations.indexWhere((d) => d.id == activeDestination);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              workspace.title,
              style: const TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          for (var i = 0; i < allDestinations.length; i++)
            ListTile(
              leading: const Icon(Icons.view_list),
              title: Text(allDestinations[i].label),
              selected: i == selectedIndex,
              onTap: () => onDestinationSelected(allDestinations[i].id),
            ),
        ],
      ),
    );
  }
}

/// Mobile panel coordinator for single-panel display with transitions.
class MobilePanelCoordinator extends StatelessWidget {
  const MobilePanelCoordinator({
    super.key,
    required this.activePanel,
    required this.panels,
  });

  final String activePanel;
  final Map<String, Widget> panels;

  @override
  Widget build(BuildContext context) {
    final panel = panels[activePanel];
    if (panel == null) {
      return Center(child: Text('Panel "$activePanel" not found'));
    }
    return panel;
  }
}
