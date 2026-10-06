import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/content.dart';
import '../providers/session_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionProvider>().user!;
    final store = context.read<FirestoreService>();
    final theme = Theme.of(context);

    final abilities = <String>[
      'Read books in the e-library',
      'Track the college bus live',
      'Chat with teachers and classmates',
      'Ask the AI assistant',
      'Read department tech news',
      if (user.role.canPostNews) 'Publish tech news',
      if (user.role.canManageBooks) 'Upload e-library books',
      if (user.role.canShareBus) 'Broadcast the bus location',
      if (user.role.canManageUsers) 'Manage users and roles',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Hello, ${user.name}', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Wrap(spacing: 8, children: [
          Chip(label: Text(user.role.label)),
          Chip(label: Text(user.department)),
          if (user.year != null) Chip(label: Text('Year ${user.year}')),
        ]),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What you can do', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final a in abilities)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      const Icon(Icons.check_circle_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(a)),
                    ]),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Latest tech news', style: theme.textTheme.titleMedium),
        StreamBuilder<List<NewsItem>>(
          stream: store.watchNews(user),
          builder: (context, snap) {
            if (snap.hasError) return ErrorState(snap.error);
            if (!snap.hasData) {
              return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()));
            }
            final items = snap.data!.take(3).toList();
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No news yet.'),
              );
            }
            return Column(children: [
              for (final n in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.newspaper),
                  title: Text(n.title),
                  subtitle: Text(
                    '${n.department} • ${n.createdAt == null ? 'just now' : DateFormat.yMMMd().format(n.createdAt!)}',
                  ),
                ),
            ]);
          },
        ),
      ],
    );
  }
}
