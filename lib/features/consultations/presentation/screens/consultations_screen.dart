import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/consultations_provider.dart';

class ConsultationsScreen extends ConsumerWidget {
  const ConsultationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consultationsAsync = ref.watch(consultationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Consultations')),
      body: consultationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erreur de chargement', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(consultationsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (consultations) {
          if (consultations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Aucune consultation', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(consultationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: consultations.length,
              itemBuilder: (context, index) {
                final c = consultations[index];
                final patient = c['appointment']?['patient'] as Map<String, dynamic>? ?? {};
                final patientName = patient['fullName'] as String? ?? 'Patient';
                final diagnosis = c['diagnosis'] as String?;
                final date = c['createdAt'] as String? ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.medical_services, size: 20),
                    ),
                    title: Text(patientName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (diagnosis != null && diagnosis.isNotEmpty)
                          Text(diagnosis, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(date.length >= 10 ? date.substring(0, 10) : date,
                            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final id = c['id']?.toString();
                      if (id != null) context.push('/consultation/$id');
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
