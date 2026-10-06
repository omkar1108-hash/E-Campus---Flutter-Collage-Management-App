import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../providers/session_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/common.dart';

/// Admin-only: assign roles (RBAC).
class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<SessionProvider>().user!;
    final store = context.read<FirestoreService>();
    final messenger = ScaffoldMessenger.of(context);
    return StreamBuilder<List<AppUser>>(
      stream: store.watchUsers(),
      builder: (context, snap) {
        if (snap.hasError) return ErrorState(snap.error);
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final users = snap.data!;
        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final u = users[i];
            final isMe = u.uid == me.uid;
            return ListTile(
              leading: CircleAvatar(child: Text(u.name.isEmpty ? '?' : u.name[0].toUpperCase())),
              title: Text(isMe ? '${u.name} (you)' : u.name),
              subtitle: Text(u.department),
              trailing: DropdownButton<UserRole>(
                value: u.role,
                // Prevent an admin from locking themselves out.
                onChanged: isMe
                    ? null
                    : (r) {
                        if (r == null) return;
                        store.setRole(u.uid, r).then(
                              (_) => showSnackOn(messenger, '${u.name} is now ${r.label}.'),
                              onError: (Object e) => showSnackOn(messenger, 'Failed: $e'),
                            );
                      },
                items: [
                  for (final r in UserRole.values)
                    DropdownMenuItem(value: r, child: Text(r.label)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
