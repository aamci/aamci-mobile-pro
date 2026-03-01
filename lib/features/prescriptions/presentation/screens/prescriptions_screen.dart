import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/prescriptions_provider.dart';

class PrescriptionsScreen extends ConsumerWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prescriptionsAsync = ref.watch(prescriptionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ordonnances')),
      body: prescriptionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erreur de chargement', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(prescriptionsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (prescriptions) {
          if (prescriptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Aucune ordonnance', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(prescriptionsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: prescriptions.length,
              itemBuilder: (context, index) {
                final p = prescriptions[index];
                final patient = p['patient'] as Map<String, dynamic>? ?? {};
                final patientName = patient['fullName'] as String? ?? 'Patient';
                final medications = p['medications'] as List? ?? [];
                final date = p['createdAt'] as String? ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.medication, color: Theme.of(context).colorScheme.primary),
                    title: Text(patientName),
                    subtitle: Text(
                      '${medications.length} médicament${medications.length > 1 ? 's' : ''} - ${date.length >= 10 ? date.substring(0, 10) : date}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final id = p['id']?.toString();
                      if (id != null) context.push('/prescription/$id');
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
