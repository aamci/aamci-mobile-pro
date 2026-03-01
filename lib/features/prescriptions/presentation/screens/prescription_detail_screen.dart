import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/prescriptions_provider.dart';

class PrescriptionDetailScreen extends ConsumerWidget {
  final String prescriptionId;

  const PrescriptionDetailScreen({super.key, required this.prescriptionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(prescriptionDetailProvider(prescriptionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Ordonnance')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erreur de chargement', style: TextStyle(color: Colors.grey[600])),
        ),
        data: (p) {
          final patient = p['patient'] as Map<String, dynamic>? ?? {};
          final patientName = patient['fullName'] as String? ?? 'Patient';
          final medications = p['medications'] as List? ?? [];
          final notes = p['notes'] as String? ?? '';
          final date = p['createdAt'] as String? ?? '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(patientName, style: Theme.of(context).textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(date.length >= 10 ? date.substring(0, 10) : date,
                          style: TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Médicaments', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (medications.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Aucun médicament', style: TextStyle(color: Colors.grey[500])),
                  ),
                )
              else
                ...medications.map((med) {
                  final m = med is Map<String, dynamic> ? med : <String, dynamic>{};
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['name'] ?? m['medication'] ?? 'Médicament',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (m['dosage'] != null) Text('Dosage : ${m['dosage']}'),
                          if (m['frequency'] != null) Text('Fréquence : ${m['frequency']}'),
                          if (m['duration'] != null) Text('Durée : ${m['duration']}'),
                          if (m['instructions'] != null)
                            Text('Instructions : ${m['instructions']}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                }),
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Notes', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(notes),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
