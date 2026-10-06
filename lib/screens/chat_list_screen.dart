import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_user.dart';
import '../providers/session_provider.dart';
import '../services/chat_ids.dart';
import '../services/firestore_service.dart';
import '../widgets/common.dart';
import 'chat_room_screen.dart';

/// Entry to the department group and one-to-one chats with teachers/friends.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  String _query = '';
  bool _teachersOnly = false;

  @override
  Widget build(BuildContext context) {
    final me = context.watch<SessionProvider>().user!;
    final store = context.read<FirestoreService>();
    return Column(
      children: [
        if (!me.role.seesAllDepartments)
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.groups)),
            title: Text('${me.department} group'),
            subtitle: const Text('Everyone in your department'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatRoomScreen(
                  chatId: departmentRoomId(me.department),
                  title: '${me.department} group',
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Find people',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('Teachers'),
              selected: _teachersOnly,
              onSelected: (v) => setState(() => _teachersOnly = v),
            ),
          ]),
        ),
        Expanded(
          child: StreamBuilder<List<AppUser>>(
            stream: store.watchUsers(
              department: me.role.seesAllDepartments ? null : me.department,
            ),
            builder: (context, snap) {
              if (snap.hasError) return ErrorState(snap.error);
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final people = snap.data!
                  .where((u) => u.uid != me.uid)
                  .where((u) => !_teachersOnly || u.role == UserRole.teacher)
                  .where((u) => u.name.toLowerCase().contains(_query))
                  .toList();
              if (people.isEmpty) {
                return const EmptyState(icon: Icons.people_outline, message: 'No one found.');
              }
              return ListView.builder(
                itemCount: people.length,
                itemBuilder: (context, i) {
                  final u = people[i];
                  return ListTile(
                    leading: CircleAvatar(child: Text(u.name.isEmpty ? '?' : u.name[0].toUpperCase())),
                    title: Text(u.name),
                    subtitle: Text('${u.role.label} • ${u.department}'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatRoomScreen(
                          chatId: directChatId(me.uid, u.uid),
                          title: u.name,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
