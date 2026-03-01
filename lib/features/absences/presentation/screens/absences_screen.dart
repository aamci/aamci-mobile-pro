import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/absences_provider.dart';

const _absenceTypes = {
  'VACATION': 'Congés',
  'SICK_LEAVE': 'Maladie',
  'TRAINING': 'Formation',
  'PERSONAL': 'Personnel',
  'OTHER': 'Autre',
};

String _fmtDate(dynamic d) {
  if (d == null) return '';
  try {
    return DateFormat('dd/MM/yyyy').format(DateTime.parse(d.toString()));
  } catch (_) {
    return d.toString();
  }
}

class AbsencesScreen extends ConsumerWidget {
  const AbsencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(absencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Absences')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text(state.error!, style: TextStyle(color: Colors.grey[600])))
              : state.absences.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('Aucune absence planifiée', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(absencesProvider.notifier).load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.absences.length,
                        itemBuilder: (context, index) {
                          final absence = state.absences[index];
                          final type = absence['type'] as String? ?? 'OTHER';
                          final typeLabel = _absenceTypes[type] ?? type;
                          final reason = absence['reason'] as String?;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(Icons.event_busy, color: Colors.orange[700]),
                              title: Text(
                                '${_fmtDate(absence['startDate'])}  →  ${_fmtDate(absence['endDate'])}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(typeLabel,
                                        style: TextStyle(fontSize: 11, color: Colors.orange[800])),
                                  ),
                                  if (reason != null && reason.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(reason,
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red[400]),
                                onPressed: () => _confirmDelete(context, ref, absence),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> absence) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette absence ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final id = absence['id']?.toString();
              if (id != null) {
                final success = await ref.read(absencesProvider.notifier).delete(id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Absence supprimée' : 'Erreur')),
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

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    DateTime? startDate;
    DateTime? endDate;
    String selectedType = 'VACATION';
    final reasonCtrl = TextEditingController();
    final formatter = DateFormat('yyyy-MM-dd');
    final displayFmt = DateFormat('dd/MM/yyyy');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nouvelle absence'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type selector
                const Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _absenceTypes.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v ?? 'VACATION'),
                ),
                const SizedBox(height: 12),
                // Date début
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    startDate != null ? displayFmt.format(startDate!) : 'Date de début *',
                    style: TextStyle(
                      color: startDate == null ? Colors.grey[600] : null,
                    ),
                  ),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (date != null) setDialogState(() => startDate = date);
                  },
                ),
                const Divider(height: 1),
                // Date fin
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    endDate != null ? displayFmt.format(endDate!) : 'Date de fin *',
                    style: TextStyle(
                      color: endDate == null ? Colors.grey[600] : null,
                    ),
                  ),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: endDate ?? startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (date != null) setDialogState(() => endDate = date);
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Motif (optionnel)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (startDate == null || endDate == null) return;
                Navigator.pop(ctx);
                final success = await ref.read(absencesProvider.notifier).create(
                      startDate: formatter.format(startDate!),
                      endDate: formatter.format(endDate!),
                      type: selectedType,
                      reason: reasonCtrl.text.trim().isNotEmpty ? reasonCtrl.text.trim() : null,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Absence créée' : 'Erreur de création')),
                  );
                }
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}
