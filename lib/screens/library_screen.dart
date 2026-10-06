import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/content.dart';
import '../providers/session_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/common.dart';

/// Lists books the user may read; tapping opens the PDF (read or download).
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _query = '';

  Future<void> _open(Book b) async {
    final uri = Uri.tryParse(b.fileUrl);
    final ok = uri != null &&
        uri.hasScheme &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) showSnack(context, 'Could not open this book.');
  }

  Future<void> _delete(Book b) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Remove book?'),
        content: Text('"${b.title}" will be removed from the library.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Remove')),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    try {
      await context.read<FirestoreService>().deleteBook(b.id);
    } catch (e) {
      if (mounted) showSnack(context, 'Could not remove book: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionProvider>().user!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search by title or author',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Book>>(
            stream: context.read<FirestoreService>().watchBooks(user),
            builder: (context, snap) {
              if (snap.hasError) return ErrorState(snap.error);
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final books = snap.data!
                  .where((b) =>
                      b.title.toLowerCase().contains(_query) ||
                      b.author.toLowerCase().contains(_query))
                  .toList();
              if (books.isEmpty) {
                return const EmptyState(
                    icon: Icons.menu_book_outlined, message: 'No books found.');
              }
              return ListView.separated(
                itemCount: books.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final b = books[i];
                  return ListTile(
                    leading: const Icon(Icons.picture_as_pdf_outlined),
                    title: Text(b.title),
                    subtitle: Text('${b.author} • ${b.department}'),
                    onTap: () => _open(b),
                    trailing: user.role.canManageBooks
                        ? IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(b),
                          )
                        : const Icon(Icons.open_in_new),
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
