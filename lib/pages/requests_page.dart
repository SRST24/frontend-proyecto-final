// lib/pages/requests_page.dart
import 'package:flutter/material.dart';
import '../api/api_client.dart';

class RequestsPage extends StatefulWidget {
  final ApiClient api;
  const RequestsPage({super.key, required this.api});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await widget.api.loadToken();
      final r = await widget.api.getRequests();
      if (!mounted) return;
      setState(() { _items = r; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _createRequestDialog() async {
    final workerCtl = TextEditingController();
    final serviceCtl = TextEditingController();
    await showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Nueva Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: workerCtl, decoration: const InputDecoration(labelText: 'Worker ID')),
            TextField(controller: serviceCtl, decoration: const InputDecoration(labelText: 'Service ID')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () async {
            final w = int.tryParse(workerCtl.text.trim()) ?? 0;
            final s = int.tryParse(serviceCtl.text.trim()) ?? 0;
            await widget.api.createRequest(workerId: w, serviceId: s);
            if (!mounted) return;
            Navigator.pop(ctx);
            await _load();
          }, child: const Text('Crear'))
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests'),
        actions: [
          if (widget.api.isClient) IconButton(
            onPressed: _createRequestDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Nueva Request',
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _items.length,
            itemBuilder: (ctx, i) {
              final e = _items[i] as Map<String, dynamic>;
              final id = e['id'];
              final status = (e['status'] ?? '').toString();
              return ListTile(
                title: Text('Request #$id'),
                subtitle: Text('Estado: $status'),
                trailing: _StatusChanger(
                  currentStatus: status,
                  isClient: widget.api.isClient,
                  onChange: (newStatus) async {
                    final rid = id is int ? id : int.tryParse(id.toString()) ?? 0;
                    await widget.api.updateRequestStatus(rid, newStatus);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Estado actualizado')));
                    await _load();
                  },
                ),
              );
            },
          ),
    );
  }
}

class _StatusChanger extends StatefulWidget {
  final String currentStatus;
  final bool isClient;
  final Future<void> Function(String) onChange;
  const _StatusChanger({required this.currentStatus, required this.isClient, required this.onChange});

  @override
  State<_StatusChanger> createState() => _StatusChangerState();
}

class _StatusChangerState extends State<_StatusChanger> {
  String? value;

  List<String> _options() {
    final s = widget.currentStatus.toLowerCase();
    if (widget.isClient) {
      if (s == 'pending') return const ['Canceled'];
      if (s == 'accepted') return const ['Completed'];
    } else { // Worker
      if (s == 'pending') return const ['Accepted'];
      if (s == 'accepted') return const ['Completed'];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final opts = _options();
    if (opts.isEmpty) return const SizedBox.shrink();
    return DropdownButton<String>(
      value: value,
      hint: const Text('Estado'),
      items: opts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) async {
        if (v == null) return;
        setState(() => value = v);
        final apiValue = (v == 'Cancelled') ? 'Canceled' : v;
        await widget.onChange(apiValue);
      },
    );
  }
}
