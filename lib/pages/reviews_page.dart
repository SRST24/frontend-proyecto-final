import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_client.dart';

class ReviewsPage extends StatefulWidget {
  final ApiClient api;
  const ReviewsPage({super.key, required this.api});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final workerId = TextEditingController();
  final rating = TextEditingController(text: '5');
  final comment = TextEditingController();

  List<Map<String, dynamic>> items = [];
  bool loading = false;
  String? error;

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final id = int.tryParse(workerId.text.trim()) ?? 0;
      final res = await widget.api.reviewsForWorker(id);
      setState(() { items = res; });
    } catch (e) {
      setState(() { error = e.toString(); });
    } finally {
      setState(() { loading = false; });
    }
  }

  Future<void> _create() async {
    setState(() { loading = true; error = null; });
    try {
      final payload = {
        'workerId': int.tryParse(workerId.text.trim()) ?? 0,
        'rating': int.tryParse(rating.text.trim()) ?? 5,
        'comment': comment.text.trim(),
      };
      await widget.api.createReview(payload);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review creada')));
    } catch (e) {
      setState(() { error = e.toString(); });
    } finally {
      setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: TextField(controller: workerId, decoration: const InputDecoration(labelText: 'workerId'))),
              const SizedBox(width: 8),
              FilledButton(onPressed: loading ? null : _load, child: const Text('Ver reviews')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 100,
                child: TextField(controller: rating, decoration: const InputDecoration(labelText: 'rating')),
              ),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: comment, decoration: const InputDecoration(labelText: 'comment'))),
              const SizedBox(width: 8),
              FilledButton(onPressed: loading ? null : _create, child: const Text('Crear')),
            ],
          ),
          const SizedBox(height: 12),
          if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
          if (loading) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final e = items[i];
                final r = (e['rating'] ?? '').toString();
                final c = (e['comment'] ?? '').toString();
                return ListTile(
                  leading: const Icon(Icons.star_outline),
                  title: Text('Rating: $r'),
                  subtitle: Text(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
