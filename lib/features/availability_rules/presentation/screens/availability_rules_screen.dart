import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/availability_rules_provider.dart';

class AvailabilityRulesScreen extends ConsumerWidget {
  const AvailabilityRulesScreen({super.key});

  static const _dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  static String _hourToStr(dynamic h) {
    if (h == null) return '';
    if (h is String) return h;
    return '${(h as int).toString().padLeft(2, '0')}:00';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(availabilityRulesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Règles de disponibilité')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRuleDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text(state.error!, style: TextStyle(color: Colors.grey[600])))
              : state.rules.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.schedule, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('Aucune règle', style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          Text('Ajoutez vos disponibilités',
                              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(availabilityRulesProvider.notifier).load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.rules.length,
                        itemBuilder: (context, index) {
                          final rule = state.rules[index];
                          final days = (rule['daysOfWeek'] as List?)?.map((d) {
                                final i = (d as int) - 1;
                                return i >= 0 && i < 7 ? _dayNames[i] : '?';
                              }).join(', ') ??
                              '';
                          final startHour = _hourToStr(rule['startHour']);
                          final endHour = _hourToStr(rule['endHour']);
                          final duration = rule['slotDurationMins'] ?? rule['slotDuration'] ?? 30;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(Icons.schedule, color: Theme.of(context).colorScheme.primary),
                              title: Text(days),
                              subtitle: Text('$startHour - $endHour  ($duration min)'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _showRuleDialog(context, ref, rule: rule),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, size: 20, color: Colors.red[400]),
                                    onPressed: () => _confirmDelete(context, ref, rule),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> rule) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette règle ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final id = rule['id']?.toString();
              if (id != null) {
                final success = await ref.read(availabilityRulesProvider.notifier).delete(id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(success ? 'Règle supprimée' : 'Erreur')),
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

  void _showRuleDialog(BuildContext context, WidgetRef ref, {Map<String, dynamic>? rule}) {
    final isEdit = rule != null;
    final selectedDays = <int>{};
    if (rule != null && rule['daysOfWeek'] is List) {
      selectedDays.addAll((rule['daysOfWeek'] as List).map((e) => e as int));
    }

    final startCtrl = TextEditingController(text: rule != null ? _hourToStr(rule['startHour']) : '08:00');
    final endCtrl = TextEditingController(text: rule != null ? _hourToStr(rule['endHour']) : '18:00');
    int duration = rule?['slotDurationMins'] ?? rule?['slotDuration'] ?? 30;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Modifier la règle' : 'Nouvelle règle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jours', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: List.generate(7, (i) {
                    final dayNum = i + 1;
                    final selected = selectedDays.contains(dayNum);
                    return FilterChip(
                      label: Text(_dayNames[i]),
                      selected: selected,
                      onSelected: (val) {
                        setDialogState(() {
                          if (val) {
                            selectedDays.add(dayNum);
                          } else {
                            selectedDays.remove(dayNum);
                          }
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: startCtrl,
                        decoration: const InputDecoration(labelText: 'Début'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: endCtrl,
                        decoration: const InputDecoration(labelText: 'Fin'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Durée du créneau', style: TextStyle(fontWeight: FontWeight.w600)),
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
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                if (selectedDays.isEmpty) return;
                Navigator.pop(ctx);
                bool success;
                if (isEdit) {
                  success = await ref.read(availabilityRulesProvider.notifier).update(
                        rule['id'].toString(),
                        daysOfWeek: selectedDays.toList()..sort(),
                        startHour: startCtrl.text,
                        endHour: endCtrl.text,
                        slotDurationMins: duration,
                      );
                } else {
                  success = await ref.read(availabilityRulesProvider.notifier).create(
                        daysOfWeek: selectedDays.toList()..sort(),
                        startHour: startCtrl.text,
                        endHour: endCtrl.text,
                        slotDurationMins: duration,
                      );
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(success ? (isEdit ? 'Règle modifiée' : 'Règle créée') : 'Erreur')),
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
