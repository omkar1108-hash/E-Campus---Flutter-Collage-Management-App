import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../providers/session_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/common.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionProvider>().user!;
    final store = context.read<FirestoreService>();
    final messenger = ScaffoldMessenger.of(context);
    return StreamBuilder<List<NewsItem>>(
      stream: store.watchNews(user),
      builder: (context, snap) {
        if (snap.hasError) return ErrorState(snap.error);
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        if (items.isEmpty) {
          return const EmptyState(
              icon: Icons.newspaper_outlined,
              message: 'No tech news for your department yet.');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final n = items[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(n.title, style: Theme.of(context).textTheme.titleMedium),
                      ),
                      if (user.role.canManageBooks || n.authorId == user.uid)
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => store.deleteNews(n.id).catchError(
                              (Object e) => showSnackOn(messenger, 'Could not delete: $e')),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Text(n.body),
                    const SizedBox(height: 8),
                    Text(
                      '${n.department} • ${n.authorName} • '
                      '${n.createdAt == null ? 'just now' : DateFormat.yMMMd().add_jm().format(n.createdAt!)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
