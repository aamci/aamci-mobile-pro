import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/appointment_kinds_provider.dart';

class AppointmentKindsScreen extends ConsumerWidget {
  const AppointmentKindsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appointmentKindsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Types de consultation')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showKindDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text(state.error!, style: TextStyle(color: Colors.grey[600])))
              : state.kinds.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.category_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('Aucun type de consultation', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(appointmentKindsProvider.notifier).load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.kinds.length,
                        itemBuilder: (context, index) {
                          final kind = state.kinds[index];
                          final name = kind['name'] as String? ?? 'Type';
                          final duration = kind['durationMins'] ?? 30;
                          final price = kind['price'];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(Icons.category, color: Theme.of(context).colorScheme.primary),
                              title: Text(name),
                              subtitle: Text(
                                '$duration min${price != null ? ' - $price XAF' : ''}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _showKindDialog(context, ref, kind: kind),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, size: 20, color: Colors.red[400]),
                                    onPressed: () => _confirmDelete(context, ref, kind),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> kind) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce type ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final id = kind['id']?.toString();
              if (id != null) {
                final success = await ref.read(appointmentKindsProvider.notifier).delete(id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Type supprimé' : 'Erreur')),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showKindDialog(BuildContext context, WidgetRef ref, {Map<String, dynamic>? kind}) {
    final isEdit = kind != null;
    final nameCtrl = TextEditingController(text: kind?['name'] ?? '');
    final priceCtrl = TextEditingController(text: kind?['price']?.toString() ?? '');
    int duration = kind?['durationMins'] ?? 30;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Modifier le type' : 'Nouveau type'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: 'Prix (optionnel)'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text('Durée', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 15, label: Text('15m')),
                      ButtonSegment(value: 30, label: Text('30m')),
                      ButtonSegment(value: 45, label: Text('45m')),
                      ButtonSegment(value: 60, label: Text('1h')),
                    ],
                    selected: {duration},
                    onSelectionChanged: (v) => setDialogState(() => duration = v.first),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                final price = double.tryParse(priceCtrl.text.trim());
                bool success;
                if (isEdit) {
                  success = await ref.read(appointmentKindsProvider.notifier).update(
                        kind['id'].toString(),
                        name: nameCtrl.text.trim(),
                        durationMins: duration,
                        price: price,
                      );
                } else {
                  success = await ref.read(appointmentKindsProvider.notifier).create(
                        name: nameCtrl.text.trim(),
                        durationMins: duration,
                        price: price,
                      );
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? (isEdit ? 'Type modifié' : 'Type créé') : 'Erreur')),
                  );
                }
              },
              child: Text(isEdit ? 'Modifier' : 'Créer'),
            ),
          ],
        ),
      ),
    );
  }
}
