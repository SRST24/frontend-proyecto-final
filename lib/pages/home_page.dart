// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'requests_page.dart';
import 'workers_page.dart';
import 'services_page.dart';
import 'reviews_page.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  final ApiClient api;
  const HomePage({super.key, required this.api});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await widget.api.loadToken();
    if (!mounted) return;
    setState(() => _booting = false);
  }

  List<_TabDef> _tabs() {
    if (!widget.api.hasToken) {
      return [
        _TabDef('Servicios', const Icon(Icons.work_outline), ServicesPage(api: widget.api)),
        _TabDef('Cuenta', const Icon(Icons.person_outline), _AccountAnon(api: widget.api)),
      ];
    }
    if (widget.api.isClient) {
      return [
        _TabDef('Servicios', const Icon(Icons.work_outline), ServicesPage(api: widget.api)),
        _TabDef('Requests', const Icon(Icons.receipt_long_outlined), RequestsPage(api: widget.api)),
        _TabDef('Reviews', const Icon(Icons.rate_review_outlined), ReviewsPage(api: widget.api)),
        _TabDef('Cuenta', const Icon(Icons.person_outline), _AccountAuthed(api: widget.api)),
      ];
    } else if (widget.api.isWorker) {
      return [
        _TabDef('Workers', const Icon(Icons.handyman_outlined), WorkersPage(api: widget.api)),
        _TabDef('Servicios', const Icon(Icons.work_outline), ServicesPage(api: widget.api)),
        _TabDef('Requests', const Icon(Icons.receipt_long_outlined), RequestsPage(api: widget.api)),
        _TabDef('Reviews', const Icon(Icons.rate_review_outlined), ReviewsPage(api: widget.api)),
        _TabDef('Cuenta', const Icon(Icons.person_outline), _AccountAuthed(api: widget.api)),
      ];
    } else {
      // Admin u otro rol
      return [
        _TabDef('Servicios', const Icon(Icons.work_outline), ServicesPage(api: widget.api)),
        _TabDef('Workers', const Icon(Icons.handyman_outlined), WorkersPage(api: widget.api)),
        _TabDef('Requests', const Icon(Icons.receipt_long_outlined), RequestsPage(api: widget.api)),
        _TabDef('Reviews', const Icon(Icons.rate_review_outlined), ReviewsPage(api: widget.api)),
        _TabDef('Cuenta', const Icon(Icons.person_outline), _AccountAuthed(api: widget.api)),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final tabs = _tabs();
    final current = tabs[_index.clamp(0, tabs.length - 1)];
    return Scaffold(
      appBar: AppBar(title: const Text('ManoVecina')),
      body: current.page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in tabs) NavigationDestination(icon: t.icon, label: t.label),
        ],
      ),
    );
  }
}

class _TabDef {
  final String label;
  final Icon icon;
  final Widget page;
  _TabDef(this.label, this.icon, this.page);
}

class _AccountAnon extends StatelessWidget {
  final ApiClient api;
  const _AccountAnon({required this.api, super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No has iniciado sesión'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage(api: api)));
              },
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountAuthed extends StatelessWidget {
  final ApiClient api;
  const _AccountAuthed({required this.api, super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rol: ${api.role ?? '-'}'),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () async {
                await api.logout();
                if (context.mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage(api: api)));
                }
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
