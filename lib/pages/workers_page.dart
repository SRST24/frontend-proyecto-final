import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_client.dart';

class WorkersPage extends StatefulWidget {
  final ApiClient api;
  const WorkersPage({super.key, required this.api});

  @override
  State<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends State<WorkersPage> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              FilledButton.icon(
                onPressed: () async {
                  await showDialog(context: context, builder: (_) => _EditWorkerDialog(api: widget.api));
                  setState(() {});
                },
                icon: const Icon(Icons.add),
                label: const Text('Crear Worker'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh),
                label: const Text('Recargar'),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: widget.api.workers(),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final items = snap.data ?? [];
              if (items.isEmpty) return const Center(child: Text('Sin workers'));
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final e = items[i];
                  final id = e['id'] ?? e['workerId'] ?? 0;
                  final name = (e['name'] ?? e['fullName'] ?? 'Worker').toString();
                  final prof = (e['profession'] ?? e['title'] ?? '').toString();
                  return ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text('$name  (#$id)'),
                    subtitle: Text(prof),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () async {
                            await showDialog(context: context, builder: (_) => _EditWorkerDialog(api: widget.api, existing: e));
                            setState(() {});
                          },
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          onPressed: () async {
                            final workerId = id is int ? id : int.tryParse(id.toString()) ?? 0;
                            await widget.api.deleteWorker(workerId);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eliminado')));
                            setState(() {});
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
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

class _EditWorkerDialog extends StatefulWidget {
  final ApiClient api;
  final Map<String, dynamic>? existing;
  const _EditWorkerDialog({required this.api, this.existing});

  @override
  State<_EditWorkerDialog> createState() => _EditWorkerDialogState();
}

class _EditWorkerDialogState extends State<_EditWorkerDialog> {
  final name = TextEditingController();
  final profession = TextEditingController();
  final bio = TextEditingController();
  final phone = TextEditingController();
  String rawJson = '';
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      name.text = (widget.existing!['name'] ?? '').toString();
      profession.text = (widget.existing!['profession'] ?? '').toString();
      bio.text = (widget.existing!['bio'] ?? '').toString();
      phone.text = (widget.existing!['phone'] ?? '').toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Editar Worker' : 'Crear Worker'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'name')),
            TextField(controller: profession, decoration: const InputDecoration(labelText: 'profession')),
            TextField(controller: bio, decoration: const InputDecoration(labelText: 'bio')),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'phone')),
            const SizedBox(height: 8),
            ExpansionTile(
              title: const Text('Payload JSON opcional'),
              children: [
                TextField(
                  maxLines: 6,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  onChanged: (v) => rawJson = v,
                ),
              ],
            ),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: loading ? null : () async {
            setState(() { loading = true; error = null; });
            try {
              final payload = <String, dynamic>{
                'name': name.text.trim(),
                'profession': profession.text.trim(),
                'bio': bio.text.trim(),
                'phone': phone.text.trim(),
              };
              if (rawJson.trim().isNotEmpty) {
                try {
                  final extra = jsonDecode(rawJson);
                  if (extra is Map<String, dynamic>) {
                    payload.addAll(extra);
                  }
                } catch (_) {}
              }
              if (isEdit) {
                final rawId = widget.existing!['id'] ?? widget.existing!['workerId'];
                final id = rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0;
                await widget.api.updateWorker(id, payload);
              } else {
                await widget.api.createWorker(payload);
              }
              if (!mounted) return;
              Navigator.pop(context);
            } catch (e) {
              if (!mounted) return;
              setState(() { error = e.toString(); });
            } finally {
              if (!mounted) return;
              setState(() { loading = false; });
            }
          },
          child: Text(loading ? 'Guardando...' : 'Guardar'),
        ),
      ],
    );
  }
}
