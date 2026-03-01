import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/medical_notes_provider.dart';

class MedicalNotesScreen extends ConsumerWidget {
  const MedicalNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(medicalNotesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notes médicales')),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erreur de chargement', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(medicalNotesProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (notes) {
          if (notes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Aucune note médicale', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(medicalNotesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final title = note['title'] as String? ?? 'Note ${index + 1}';
                final content = note['content'] as String? ?? '';
                final patient = note['patient'] as Map<String, dynamic>?;
                final patientName = patient?['fullName'] as String? ?? '';
                final date = note['createdAt'] as String? ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, size: 18, color: Colors.red[400]),
                              onPressed: () async {
                                final id = note['id']?.toString();
                                if (id != null) {
                                  await ref.read(medicalNotesRemoteProvider).deleteNote(id);
                                  ref.invalidate(medicalNotesProvider);
                                }
                              },
                            ),
                          ],
                        ),
                        if (patientName.isNotEmpty)
                          Text(patientName, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(content, maxLines: 3, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(date.length >= 10 ? date.substring(0, 10) : date,
                            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
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
