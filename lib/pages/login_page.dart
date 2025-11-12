import 'package:flutter/material.dart';
import '../api/api_client.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  final ApiClient api;
  const LoginPage({super.key, required this.api});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                TextField(controller: password, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                const SizedBox(height: 16),
                if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: loading ? null : () async {
                    setState(() { loading = true; error = null; });
                    try {
                      await widget.api.login(email.text.trim(), password.text.trim());
                      if (!mounted) return;
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomePage(api: widget.api)));
                    } catch (e) {
                      if (!mounted) return;
                      setState(() { error = e.toString(); });
                    } finally {
                      if (!mounted) return;
                      setState(() { loading = false; });
                    }
                  },
                  child: loading ? const CircularProgressIndicator() : const Text('Entrar'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterPage(api: widget.api)));
                  },
                  child: const Text('Crear cuenta'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  final ApiClient api;
  const RegisterPage({super.key, required this.api});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  String role = 'Client'; // Client/Worker
  bool loading = false;
  String? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
                const SizedBox(height: 8),
                TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                TextField(controller: password, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: role,
                  items: const [
                    DropdownMenuItem(value: 'Client', child: Text('Client')),
                    DropdownMenuItem(value: 'Worker', child: Text('Worker')),
                  ],
                  onChanged: (v) => setState(() => role = v ?? 'Client'),
                  decoration: const InputDecoration(labelText: 'Rol'),
                ),
                const SizedBox(height: 16),
                if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: loading ? null : () async {
                    setState(() { loading = true; error = null; });
                    try {
                      await widget.api.register(name.text.trim(), email.text.trim(), password.text.trim(), role);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuenta creada. Inicia sesión.')));
                      Navigator.of(context).pop();
                    } catch (e) {
                      if (!mounted) return;
                      setState(() { error = e.toString(); });
                    } finally {
                      if (!mounted) return;
                      setState(() { loading = false; });
                    }
                  },
                  child: loading ? const CircularProgressIndicator() : const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
