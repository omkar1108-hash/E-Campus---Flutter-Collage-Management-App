import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/app_user.dart';
import '../providers/session_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/common.dart';

/// Class representatives / teachers / admins publish news for a department.
class PostNewsScreen extends StatefulWidget {
  const PostNewsScreen({super.key});

  @override
  State<PostNewsScreen> createState() => _PostNewsScreenState();
}

class _PostNewsScreenState extends State<PostNewsScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  String? _department;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (!_form.currentState!.validate()) return;
    final user = context.read<SessionProvider>().user!;
    final dept = _department ?? user.department;
    setState(() => _busy = true);
    try {
      await context.read<FirestoreService>().postNews(
            author: user,
            title: _title.text.trim(),
            body: _body.text.trim(),
            department: dept,
          );
      if (!mounted) return;
      showSnack(context, 'News published to $dept.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showSnack(context, 'Could not publish: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionProvider>().user!;
    // Class reps post to their own department; teachers/admins to any.
    final canPickDept = user.role != UserRole.classRep;
    return Scaffold(
      appBar: AppBar(title: const Text('Post Tech News')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Headline', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _body,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(labelText: 'Details', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _department ?? user.department,
              decoration: const InputDecoration(
                  labelText: 'Department', border: OutlineInputBorder()),
              items: [
                for (final d in AppConfig.departments)
                  DropdownMenuItem(value: d, child: Text(d)),
              ],
              onChanged: canPickDept ? (v) => setState(() => _department = v) : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _post,
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }
}
