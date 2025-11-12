import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_client.dart';

class RequestsPage extends StatefulWidget {
  final ApiClient api;
  const RequestsPage({super.key, required this.api});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
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
                  await showDialog(context: context, builder: (_) => _CreateRequestDialog(api: widget.api));
                  setState(() {});
                },
                icon: const Icon(Icons.add),
                label: const Text('Nueva Request'),
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
            future: widget.api.myRequests(),
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final items = snap.data ?? [];
              if (items.isEmpty) return const Center(child: Text('Sin requests'));
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final e = items[i];
                  final id = e['id'] ?? e['requestId'] ?? 0;
                  final status = (e['status'] ?? '').toString();
                  final desc = (e['description'] ?? e['details'] ?? '').toString();
                  return ListTile(
                    title: Text('Request #$id  •  $status'),
                    subtitle: Text(desc),
                    trailing: _StatusChanger(
                      onChange: (newStatus) async {
                        final rid = id is int ? id : int.tryParse(id.toString()) ?? 0;
                        await widget.api.updateRequestStatus(rid, newStatus);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estado actualizado')));
                        setState(() {});
                      },
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

class _CreateRequestDialog extends StatefulWidget {
  final ApiClient api;
  const _CreateRequestDialog({required this.api});

  @override
  State<_CreateRequestDialog> createState() => _CreateRequestDialogState();
}

class _CreateRequestDialogState extends State<_CreateRequestDialog> {
  final workerId = TextEditingController();
  final serviceId = TextEditingController();
  final description = TextEditingController();
  String payloadJson = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear Request'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: workerId, decoration: const InputDecoration(labelText: 'workerId')),
            TextField(controller: serviceId, decoration: const InputDecoration(labelText: 'serviceId (opcional)')),
            TextField(controller: description, decoration: const InputDecoration(labelText: 'description')),
            const SizedBox(height: 8),
            ExpansionTile(
              title: const Text('Payload JSON (opcional si tu esquema es distinto)'),
              children: [
                TextField(
                  maxLines: 6,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  onChanged: (v) => payloadJson = v,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () async {
            Map<String, dynamic> payload = {
              'workerId': int.tryParse(workerId.text.trim()) ?? 0,
              'serviceId': int.tryParse(serviceId.text.trim()),
              'description': description.text.trim(),
            };
            if (payloadJson.trim().isNotEmpty) {
              try { payload = Map<String, dynamic>.from(jsonDecode(payloadJson)); } catch (_) {}
            }
            await widget.api.createRequest(payload);
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Crear'),
        ),
      ],
    );
  }
}

class _StatusChanger extends StatefulWidget {
  final Future<void> Function(String) onChange;
  const _StatusChanger({required this.onChange});

  @override
  State<_StatusChanger> createState() => _StatusChangerState();
}

class _StatusChangerState extends State<_StatusChanger> {
  String? value;
  final options = const ['Pending','Accepted','Completed','Cancelled'];

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: value,
      hint: const Text('Estado'),
      items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) async {
        if (v == null) return;
        setState(() => value = v);
        await widget.onChange(v);
      },
    );
  }
}
