import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/consultations_provider.dart';

class ConsultationDetailScreen extends ConsumerWidget {
  final String consultationId;

  const ConsultationDetailScreen({super.key, required this.consultationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(consultationDetailProvider(consultationId));

    return Scaffold(
      appBar: AppBar(title: const Text('Consultation')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Erreur de chargement', style: TextStyle(color: Colors.grey[600])),
        ),
        data: (c) {
          final patient = c['appointment']?['patient'] as Map<String, dynamic>? ?? {};
          final patientName = patient['fullName'] as String? ?? 'Patient';
          final diagnosis = c['diagnosis'] as String? ?? '';
          final notes = c['notes'] as String? ?? '';
          final date = c['createdAt'] as String? ?? '';

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
              if (diagnosis.isNotEmpty) ...[
                Text('Diagnostic', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(diagnosis),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (notes.isNotEmpty) ...[
                Text('Notes', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(notes),
                  ),
                ),
              ],
              if (diagnosis.isEmpty && notes.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Text('Aucun détail enregistré', style: TextStyle(color: Colors.grey[500])),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
