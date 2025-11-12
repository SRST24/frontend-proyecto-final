import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'workers_page.dart';
import 'requests_page.dart';
import 'reviews_page.dart';

class HomePage extends StatefulWidget {
  final ApiClient api;
  const HomePage({super.key, required this.api});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _ServicesTab(api: widget.api),
      WorkersPage(api: widget.api),
      RequestsPage(api: widget.api),
      ReviewsPage(api: widget.api),
      _AccountTab(api: widget.api),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('ManoVecina')),
      body: tabs[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_repair_service_outlined), label: 'Servicios'),
          NavigationDestination(icon: Icon(Icons.handyman_outlined), label: 'Workers'),
          NavigationDestination(icon: Icon(Icons.request_page_outlined), label: 'Requests'),
          NavigationDestination(icon: Icon(Icons.reviews_outlined), label: 'Reviews'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Cuenta'),
        ],
      ),
    );
  }
}

class _ServicesTab extends StatelessWidget {
  final ApiClient api;
  const _ServicesTab({required this.api});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: api.services(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final items = snap.data ?? [];
        if (items.isEmpty) return const Center(child: Text('Sin servicios'));
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final e = items[i];
            final title = (e['title'] ?? e['name'] ?? e['serviceName'] ?? 'Servicio').toString();
            final desc = (e['description'] ?? e['summary'] ?? '').toString();
            return ListTile(
              title: Text(title),
              subtitle: Text(desc),
            );
          },
        );
      },
    );
  }
}

class _AccountTab extends StatelessWidget {
  final ApiClient api;
  const _AccountTab({required this.api});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(api.hasToken ? 'Sesión activa' : 'Sin sesión'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              await api.logout();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesión cerrada')));
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
