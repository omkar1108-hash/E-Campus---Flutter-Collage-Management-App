import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../providers/session_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/common.dart';

/// Teachers/admins add a book by uploading a PDF or pasting a link.
class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  static const _maxBytes = 25 * 1024 * 1024;

  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _author = TextEditingController();
  final _url = TextEditingController();
  String _department = 'ALL';
  PlatformFile? _file;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final f = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    if (f == null) return;
    final size = await f.length() ?? 0;
    if (!mounted) return;
    if (size > _maxBytes) {
      showSnack(context, 'PDF is larger than 25 MB.');
      return;
    }
    setState(() => _file = f);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_file == null && _url.text.trim().isEmpty) {
      showSnack(context, 'Attach a PDF or paste a link.');
      return;
    }
    final store = context.read<FirestoreService>();
    final user = context.read<SessionProvider>().user!;
    setState(() => _busy = true);
    try {
      final link = _file != null
          ? await store.uploadBookFile(_file!.name, await _file!.readAsBytes())
          : _url.text.trim();
      await store.addBook(
        uploader: user,
        title: _title.text.trim(),
        author: _author.text.trim(),
        department: _department,
        fileUrl: link,
      );
      if (!mounted) return;
      showSnack(context, 'Book added.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showSnack(context, 'Upload failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Book')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _author,
              decoration: const InputDecoration(labelText: 'Author', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _department,
              decoration: const InputDecoration(
                  labelText: 'Visible to', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: 'ALL', child: Text('All departments')),
                for (final d in AppConfig.departments)
                  DropdownMenuItem(value: d, child: Text(d)),
              ],
              onChanged: (v) => setState(() => _department = v!),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.attach_file),
              label: Text(_file == null ? 'Choose PDF (max 25 MB)' : _file!.name),
            ),
            const SizedBox(height: 8),
            const Center(child: Text('or')),
            const SizedBox(height: 8),
            TextFormField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                  labelText: 'Link to PDF (https://…)', border: OutlineInputBorder()),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return null;
                final u = Uri.tryParse(t);
                return (u != null && (u.scheme == 'https' || u.scheme == 'http') && u.host.isNotEmpty)
                    ? null
                    : 'Enter a valid http(s) link';
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add to library'),
            ),
          ],
        ),
      ),
    );
  }
}
