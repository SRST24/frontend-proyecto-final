// lib/pages/services_page.dart
import 'package:flutter/material.dart';
import '../api/api_client.dart';

class ServicesPage extends StatefulWidget {
  final ApiClient api;
  const ServicesPage({super.key, required this.api});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.api.services();
      if (!mounted) return;
      setState(() { _services = data; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _openForm({Map<String, dynamic>? initial}) async {
    final name = TextEditingController(text: initial?['name']?.toString() ?? '');
    final desc = TextEditingController(text: initial?['description']?.toString() ?? '');
    final isEdit = initial != null;
    await showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: Text(isEdit ? 'Editar servicio' : 'Nuevo servicio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: desc, decoration: const InputDecoration(labelText: 'Descripción')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final body = {'name': name.text.trim(), 'description': desc.text.trim()};
              try {
                if (isEdit) {
                  final id = int.tryParse(initial!['id'].toString()) ?? 0;
                  // No hay endpoint PUT concreto en este ejemplo, ajusta si existe.
                  // await widget.api.updateService(id, body);
                } else {
                  // Si tu backend permite POST /api/services para Worker autenticado:
                  // Implementa el método createService en ApiClient si aún no existe.
                  // Por ahora mostramos un aviso.
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Implementa createService en ApiClient si está habilitado en backend.')));
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
        title: const Text('Servicios'),
        actions: [
          if (!widget.api.isClient) IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nuevo servicio',
            onPressed: () => _openForm(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: _services.length,
              itemBuilder: (ctx, i) {
                final s = _services[i];
                return ListTile(
                  title: Text(s['name']?.toString() ?? 'Sin nombre'),
                  subtitle: Text(s['description']?.toString() ?? ''),
                  trailing: (!widget.api.isClient) ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openForm(initial: s),
                        tooltip: 'Editar servicio',
                      ),
                      // Podrías agregar delete si el backend lo permite y expones un método en ApiClient.
                    ],
                  ) : null,
                );
              },
            ),
    );
  }
}
