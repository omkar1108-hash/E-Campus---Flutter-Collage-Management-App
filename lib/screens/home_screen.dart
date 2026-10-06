import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../providers/session_provider.dart';
import 'add_book_screen.dart';
import 'ai_chat_screen.dart';
import 'bus_sharing_screen.dart';
import 'bus_tracking_screen.dart';
import 'chat_list_screen.dart';
import 'dashboard_screen.dart';
import 'library_screen.dart';
import 'manage_users_screen.dart';
import 'news_screen.dart';
import 'post_news_screen.dart';

/// One entry in the navigation drawer.
class DrawerEntry {
  const DrawerEntry(this.title, this.icon, {this.page, this.pushed, this.visibleTo});

  final String title;
  final IconData icon;

  /// Builds the screen shown in the home body when selected.
  final Widget Function()? page;

  /// Builds a screen pushed on top of home (for action-style entries).
  final Widget Function()? pushed;

  /// RBAC rule; null means everyone.
  final bool Function(UserRole role)? visibleTo;
}

/// Role-based drawer: students get the core features; class representatives,
/// teachers and admins see extra management entries.
List<DrawerEntry> drawerEntriesFor(UserRole role) {
  final all = <DrawerEntry>[
    DrawerEntry('Dashboard', Icons.dashboard_outlined, page: () => const DashboardScreen()),
    DrawerEntry('E-Library', Icons.menu_book_outlined, page: () => const LibraryScreen()),
    DrawerEntry('Bus Tracking', Icons.directions_bus_outlined, page: () => const BusTrackingScreen()),
    DrawerEntry('Chat', Icons.chat_bubble_outline, page: () => const ChatListScreen()),
    DrawerEntry('AI Assistant', Icons.smart_toy_outlined, page: () => const AiChatScreen()),
    DrawerEntry('Tech News', Icons.newspaper_outlined, page: () => const NewsScreen()),
    DrawerEntry('Post Tech News', Icons.edit_note,
        pushed: () => const PostNewsScreen(), visibleTo: (r) => r.canPostNews),
    DrawerEntry('Upload Book', Icons.upload_file,
        pushed: () => const AddBookScreen(), visibleTo: (r) => r.canManageBooks),
    DrawerEntry('Broadcast Bus Location', Icons.gps_fixed,
        pushed: () => const BusSharingScreen(), visibleTo: (r) => r.canShareBus),
    DrawerEntry('Manage Users', Icons.admin_panel_settings_outlined,
        page: () => const ManageUsersScreen(), visibleTo: (r) => r.canManageUsers),
  ];
  return all.where((e) => e.visibleTo == null || e.visibleTo!(role)).toList();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selected = 'Dashboard';

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionProvider>().user!;
    final entries = drawerEntriesFor(user.role);
    final current = entries.firstWhere(
      (e) => e.title == _selected && e.page != null,
      orElse: () => entries.first,
    );

    return Scaffold(
      appBar: AppBar(title: Text(current.title)),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user.name),
              accountEmail: Text('${user.role.label} • ${user.department}'),
              currentAccountPicture: CircleAvatar(
                child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase()),
              ),
            ),
            for (final e in entries)
              ListTile(
                leading: Icon(e.icon),
                title: Text(e.title),
                selected: e.page != null && e.title == current.title,
                onTap: () {
                  Navigator.pop(context); // close drawer
                  if (e.pushed != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => e.pushed!()));
                  } else {
                    setState(() => _selected = e.title);
                  }
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () {
                Navigator.pop(context);
                context.read<SessionProvider>().signOut();
              },
            ),
          ],
        ),
      ),
      body: current.page!(),
    );
  }
}
