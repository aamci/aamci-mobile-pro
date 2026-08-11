import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/questionnaires_provider.dart';

const _typeLabels = {
  'YES_NO': 'Oui/Non',
  'TEXT': 'Texte libre',
  'MULTIPLE_CHOICE': 'Choix multiple',
  'RATING': 'Note',
  'DATE': 'Date',
};

class QuestionnairesScreen extends ConsumerStatefulWidget {
  const QuestionnairesScreen({super.key});

  @override
  ConsumerState<QuestionnairesScreen> createState() => _QuestionnairesScreenState();
}

class _QuestionnairesScreenState extends ConsumerState<QuestionnairesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(questionnairesProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questionnairesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Questionnaires'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.read(questionnairesProvider.notifier).load(),
          ),
        ],
      ),
      body: Builder(builder: (context) {
        if (state.isLoading && state.questionnaires.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null && state.questionnaires.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
                const SizedBox(height: 12),
                Text(
                  'Erreur de chargement',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  state.error!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.read(questionnairesProvider.notifier).load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (state.questionnaires.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Aucun questionnaire',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez votre premier questionnaire\nen appuyant sur le bouton +',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(questionnairesProvider.notifier).load(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.questionnaires.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final q = state.questionnaires[i];
              return _QuestionnaireCard(
                questionnaire: q,
                onToggleActive: (isActive) async {
                  final ok = await ref
                      .read(questionnairesProvider.notifier)
                      .setActive(q['id'], isActive);
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur lors de la mise à jour'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                onDelete: () => _confirmDelete(q),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
      ),
    );
  }

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _CreateQuestionnaireSheet(
        onSave: (title, description) async {
          final ok = await ref.read(questionnairesProvider.notifier).create(
                title: title,
                description: description,
              );
          if (ctx.mounted) Navigator.pop(ctx);
          if (!ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erreur lors de la création'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> questionnaire) {
    final title = questionnaire['title'] as String? ?? 'ce questionnaire';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le questionnaire ?'),
        content: Text('"$title" sera définitivement supprimé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref
                  .read(questionnairesProvider.notifier)
                  .delete(questionnaire['id']);
              if (!ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erreur lors de la suppression'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _QuestionnaireCard extends StatelessWidget {
  final Map<String, dynamic> questionnaire;
  final void Function(bool) onToggleActive;
  final VoidCallback onDelete;

  const _QuestionnaireCard({
    required this.questionnaire,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = questionnaire['title'] as String? ?? '';
    final description = questionnaire['description'] as String?;
    final isActive = questionnaire['isActive'] as bool? ?? false;
    final questions = questionnaire['questions'] as List? ?? [];
    final questionCount = questions.length;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? const BorderSide(color: Color(0xFFF59E0B), width: 1.5)
            : BorderSide(color: Colors.grey[200]!),
      ),
      elevation: isActive ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.quiz_outlined,
                      color: Color(0xFFF59E0B), size: 22),
                ),
                const SizedBox(width: 12),
                // Title + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  tooltip: 'Supprimer',
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Question count chip
                _InfoChip(
                  icon: Icons.help_outline,
                  label: '$questionCount question${questionCount > 1 ? 's' : ''}',
                  color: const Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                // Status badge
                _InfoChip(
                  icon: isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
                  label: isActive ? 'Actif' : 'Inactif',
                  color: isActive ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
                ),
                const Spacer(),
                // Toggle switch
                Row(
                  children: [
                    Text(
                      isActive ? 'Activer' : 'Désactivé',
                      style: TextStyle(
                        fontSize: 12,
                        color: isActive ? const Color(0xFF16A34A) : Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: isActive,
                      onChanged: onToggleActive,
                      activeThumbColor: const Color(0xFF16A34A),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ],
            ),
            // Questions preview
            if (questions.isNotEmpty) ...[
              const Divider(height: 16),
              ...questions
                  .cast<Map<String, dynamic>>()
                  .take(3)
                  .map((q) => _QuestionPreviewRow(question: q)),
              if (questions.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '+ ${questions.length - 3} autre${questions.length - 3 > 1 ? 's' : ''} question${questions.length - 3 > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuestionPreviewRow extends StatelessWidget {
  final Map<String, dynamic> question;

  const _QuestionPreviewRow({required this.question});

  @override
  Widget build(BuildContext context) {
    final text = question['text'] as String? ?? '';
    final type = question['type'] as String? ?? '';
    final required = question['required'] as bool? ?? false;
    final typeLabel = _typeLabels[type] ?? type;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.arrow_right, size: 16, color: Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              typeLabel,
              style: const TextStyle(fontSize: 10, color: Color(0xFFF59E0B)),
            ),
          ),
          if (required) ...[
            const SizedBox(width: 4),
            const Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ──────────────── Create Bottom Sheet ────────────────

class _CreateQuestionnaireSheet extends StatefulWidget {
  final Future<void> Function(String title, String? description) onSave;

  const _CreateQuestionnaireSheet({required this.onSave});

  @override
  State<_CreateQuestionnaireSheet> createState() => _CreateQuestionnaireSheetState();
}

class _CreateQuestionnaireSheetState extends State<_CreateQuestionnaireSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _titleController.text.trim().isNotEmpty && !_saving;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.quiz_outlined, color: Color(0xFFF59E0B), size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Nouveau questionnaire',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Titre *',
                hintText: 'Ex: Questionnaire cardio',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
                hintText: 'Décrivez l\'objectif de ce questionnaire...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous pourrez ajouter des questions depuis l\'interface web.',
              style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: canSave
                    ? () async {
                        setState(() => _saving = true);
                        await widget.onSave(
                          _titleController.text.trim(),
                          _descController.text.trim().isEmpty
                              ? null
                              : _descController.text.trim(),
                        );
                        if (mounted) setState(() => _saving = false);
                      }
                    : null,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: const Text('Créer le questionnaire'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
