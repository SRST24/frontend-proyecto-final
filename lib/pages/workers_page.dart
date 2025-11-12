// lib/pages/workers_page.dart
import 'package:flutter/material.dart';
import '../api/api_client.dart';

class WorkersPage extends StatefulWidget {
  final ApiClient api;
  const WorkersPage({super.key, required this.api});

  @override
  State<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends State<WorkersPage> {
  List<Map<String, dynamic>> _workers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await widget.api.loadToken();
      final w = await widget.api.getWorkers();
      if (!mounted) return;
      setState(() {
        _workers = w.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _openForm({Map<String, dynamic>? initial}) async {
    final name = TextEditingController(text: initial?['name']?.toString() ?? '');
    final phone = TextEditingController(text: initial?['phone']?.toString() ?? '');
    final desc = TextEditingController(text: initial?['description']?.toString() ?? '');
    final isEdit = initial != null;
    await showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: Text(isEdit ? 'Editar perfil' : 'Crear perfil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'Teléfono')),
              TextField(controller: desc, decoration: const InputDecoration(labelText: 'Descripción')),
              const SizedBox(height: 8),
              const Text('Nota: sólo el dueño del perfil puede modificarlo.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final body = {
                'name': name.text.trim(),
                'phone': phone.text.trim(),
                'description': desc.text.trim(),
              };
              try {
                if (isEdit) {
                  final id = int.tryParse(initial!['id'].toString()) ?? 0;
                  await widget.api.updateWorker(id, body);
                } else {
                  await widget.api.createWorker(body);
                }
                if (!mounted) return;
                Navigator.pop(ctx);
                await _load();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: Text(isEdit ? 'Guardar' : 'Crear'),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workers'),
        actions: [
          if (widget.api.isWorker) IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Crear mi perfil',
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _workers.length,
              itemBuilder: (ctx, i) {
                final e = _workers[i];
                final id = e['id'];
                final name = e['name']?.toString() ?? 'Sin nombre';
                return ListTile(
                  title: Text(name),
                  subtitle: Text('ID: $id'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.api.isWorker)
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openForm(initial: e),
                          tooltip: 'Editar mi perfil',
                        ),
                      if (widget.api.isWorker)
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Eliminar'),
                                content: const Text('¿Seguro que deseas eliminar tu perfil?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
                                ],
                              ),
                            );
                            if (ok != true) return;
                            try {
                              await widget.api.deleteWorker(int.tryParse(id.toString()) ?? 0);
                              await _load();
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          },
                          tooltip: 'Eliminar mi perfil',
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
