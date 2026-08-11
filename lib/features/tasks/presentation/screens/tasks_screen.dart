import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/tasks_provider.dart';

const _statusLabels = {
  'TODO': 'À faire',
  'IN_PROGRESS': 'En cours',
  'DONE': 'Terminé',
  'CANCELLED': 'Annulé',
};
const _statusColors = {
  'TODO': Color(0xFF6B7280),
  'IN_PROGRESS': Color(0xFF2563EB),
  'DONE': Color(0xFF16A34A),
  'CANCELLED': Color(0xFFDC2626),
};
const _priorityColors = {
  'LOW': Color(0xFF9CA3AF),
  'MEDIUM': Color(0xFF2563EB),
  'HIGH': Color(0xFFF97316),
  'URGENT': Color(0xFFDC2626),
};
const _priorityLabels = {
  'LOW': 'Basse',
  'MEDIUM': 'Moyenne',
  'HIGH': 'Haute',
  'URGENT': 'Urgent',
};
const _categoryLabels = {
  'FOLLOW_UP': 'Suivi',
  'CALL': 'Appel',
  'PRESCRIPTION': 'Prescription',
  'LAB_REVIEW': 'Labo',
  'ADMIN': 'Admin',
  'APPOINTMENT': 'RDV',
  'OTHER': 'Autre',
};
const _columns = ['TODO', 'IN_PROGRESS', 'DONE', 'CANCELLED'];

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _scopeFilter = 'all'; // all | doctor | patient
  String _priorityFilter = 'all';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _columns.length, vsync: this);
    Future.microtask(() => ref.read(tasksProvider.notifier).load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> tasks, String status) {
    return tasks.where((t) {
      if (t['status'] != status) return false;
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        final title = (t['title'] ?? '').toString().toLowerCase();
        final desc = (t['description'] ?? '').toString().toLowerCase();
        final patient = (t['patient']?['fullName'] ?? '').toString().toLowerCase();
        if (!title.contains(q) && !desc.contains(q) && !patient.contains(q)) return false;
      }
      if (_priorityFilter != 'all' && t['priority'] != _priorityFilter) return false;
      if (_scopeFilter == 'patient' && t['patient'] == null) return false;
      if (_scopeFilter == 'doctor' && t['patient'] != null) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tasksProvider);
    final stats = state.stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tâches'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(tasksProvider.notifier).load(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _columns.map((s) {
            final count = _filtered(state.tasks, s).length;
            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _statusColors[s],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(_statusLabels[s]!),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _statusColors[s]!.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _statusColors[s],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // Stats + filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                if (stats != null)
                  Row(
                    children: [
                      _StatChip(label: '${stats['todo'] ?? 0} à faire', color: const Color(0xFF6B7280)),
                      const SizedBox(width: 8),
                      _StatChip(label: '${stats['inProgress'] ?? 0} en cours', color: const Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      if ((stats['overdue'] ?? 0) > 0)
                        _StatChip(label: '${stats['overdue']} retard', color: const Color(0xFFDC2626)),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Rechercher...',
                          prefixIcon: Icon(Icons.search, size: 20),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: _scopeFilter == 'all'
                          ? 'Scope'
                          : _scopeFilter == 'doctor'
                              ? 'Médecin'
                              : 'Patient',
                      icon: Icons.filter_list,
                      onTap: () => _showScopeFilter(),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: _priorityFilter == 'all' ? 'Priorité' : _priorityLabels[_priorityFilter]!,
                      icon: Icons.flag_outlined,
                      onTap: () => _showPriorityFilter(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Kanban columns as tabs
          Expanded(
            child: state.isLoading && state.tasks.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: _columns.map((status) {
                      final colTasks = _filtered(state.tasks, status);
                      return _TaskColumn(
                        status: status,
                        tasks: colTasks,
                        onStatusChange: (task, newStatus) {
                          ref.read(tasksProvider.notifier).updateStatus(task['id'], newStatus);
                        },
                        onEdit: (task) => _showTaskForm(task: task),
                        onDelete: (task) => _confirmDelete(task),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle tâche'),
        backgroundColor: const Color(0xFF0D9488),
      ),
    );
  }

  void _showScopeFilter() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Toutes'),
              trailing: _scopeFilter == 'all' ? const Icon(Icons.check, color: Color(0xFF0D9488)) : null,
              onTap: () { setState(() => _scopeFilter = 'all'); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.work_outline),
              title: const Text('Mes tâches (Médecin)'),
              trailing: _scopeFilter == 'doctor' ? const Icon(Icons.check, color: Color(0xFF0D9488)) : null,
              onTap: () { setState(() => _scopeFilter = 'doctor'); Navigator.pop(context); },
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Tâches patients'),
              trailing: _scopeFilter == 'patient' ? const Icon(Icons.check, color: Color(0xFF0D9488)) : null,
              onTap: () { setState(() => _scopeFilter = 'patient'); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }

  void _showPriorityFilter() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Toutes priorités'),
              trailing: _priorityFilter == 'all' ? const Icon(Icons.check, color: Color(0xFF0D9488)) : null,
              onTap: () { setState(() => _priorityFilter = 'all'); Navigator.pop(context); },
            ),
            ...['URGENT', 'HIGH', 'MEDIUM', 'LOW'].map((p) => ListTile(
              leading: Icon(Icons.flag, color: _priorityColors[p]),
              title: Text(_priorityLabels[p]!),
              trailing: _priorityFilter == p ? const Icon(Icons.check, color: Color(0xFF0D9488)) : null,
              onTap: () { setState(() => _priorityFilter = p); Navigator.pop(context); },
            )),
          ],
        ),
      ),
    );
  }

  void _showTaskForm({Map<String, dynamic>? task}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _TaskFormSheet(
        task: task,
        onSave: (data) async {
          bool ok;
          if (task != null) {
            ok = await ref.read(tasksProvider.notifier).updateTask(task['id'], data);
          } else {
            ok = await ref.read(tasksProvider.notifier).createTask(
              title: data['title'],
              description: data['description'],
              priority: data['priority'],
              category: data['category'],
              status: data['status'],
              dueDate: data['dueDate'],
              patientId: data['patientId'],
              tags: List<String>.from(data['tags'] ?? []),
            );
          }
          if (ctx.mounted) Navigator.pop(ctx);
          if (!ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erreur lors de la sauvegarde'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la tâche ?'),
        content: Text('"${task['title']}"'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(tasksProvider.notifier).deleteTask(task['id']);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _TaskColumn extends StatelessWidget {
  final String status;
  final List<Map<String, dynamic>> tasks;
  final void Function(Map<String, dynamic>, String) onStatusChange;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const _TaskColumn({
    required this.status,
    required this.tasks,
    required this.onStatusChange,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Aucune tâche', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tasks.length,
      itemBuilder: (context, i) => _TaskCard(
        task: tasks[i],
        onStatusChange: onStatusChange,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final void Function(Map<String, dynamic>, String) onStatusChange;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onDelete;

  const _TaskCard({
    required this.task,
    required this.onStatusChange,
    required this.onEdit,
    required this.onDelete,
  });

  bool _isOverdue() {
    final due = task['dueDate'];
    if (due == null) return false;
    final status = task['status'];
    if (status == 'DONE' || status == 'CANCELLED') return false;
    return DateTime.parse(due).isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final priority = task['priority'] as String? ?? 'MEDIUM';
    final category = task['category'] as String? ?? 'OTHER';
    final patient = task['patient'] as Map<String, dynamic>?;
    final status = task['status'] as String? ?? 'TODO';
    final dueDate = task['dueDate'] as String?;
    final overdue = _isOverdue();
    final isDone = status == 'DONE';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: overdue
            ? const BorderSide(color: Color(0xFFDC2626), width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8, top: 2),
                  decoration: BoxDecoration(
                    color: _priorityColors[priority],
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    task['title'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                  onSelected: (v) {
                    if (v == 'edit') onEdit(task);
                    if (v == 'delete') onDelete(task);
                    if (v.startsWith('status:')) onStatusChange(task, v.split(':')[1]);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    const PopupMenuDivider(),
                    ...['TODO', 'IN_PROGRESS', 'DONE', 'CANCELLED'].where((s) => s != status).map(
                      (s) => PopupMenuItem(
                        value: 'status:$s',
                        child: Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(color: _statusColors[s], shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            Text('→ ${_statusLabels[s]}'),
                          ],
                        ),
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            if (task['description'] != null && (task['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task['description'],
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _InfoChip(
                  label: _categoryLabels[category] ?? category,
                  color: const Color(0xFF0D9488),
                ),
                if (dueDate != null)
                  _InfoChip(
                    label: DateFormat('d MMM', 'fr_FR').format(DateTime.parse(dueDate)),
                    color: overdue ? const Color(0xFFDC2626) : const Color(0xFF6B7280),
                    icon: Icons.calendar_today,
                  ),
                if (patient != null)
                  _InfoChip(
                    label: patient['fullName'] ?? '',
                    color: const Color(0xFF0D9488),
                    icon: Icons.person_outline,
                  )
                else
                  _InfoChip(
                    label: 'Médecin',
                    color: const Color(0xFF6B7280),
                    icon: Icons.work_outline,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _InfoChip({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}

// ──────────────── Task Form Sheet ────────────────

class _TaskFormSheet extends StatefulWidget {
  final Map<String, dynamic>? task;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _TaskFormSheet({this.task, required this.onSave});

  @override
  State<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<_TaskFormSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'MEDIUM';
  String _category = 'OTHER';
  String _status = 'TODO';
  String _scope = 'doctor'; // doctor | patient
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    if (t != null) {
      _titleController.text = t['title'] ?? '';
      _descController.text = t['description'] ?? '';
      _priority = t['priority'] ?? 'MEDIUM';
      _category = t['category'] ?? 'OTHER';
      _status = t['status'] ?? 'TODO';
      _scope = t['patient'] != null ? 'patient' : 'doctor';
      if (t['dueDate'] != null) _dueDate = DateTime.parse(t['dueDate']);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
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
                Text(
                  isEditing ? 'Modifier la tâche' : 'Nouvelle tâche',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Type de tâche
            const Text('Type de tâche', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ScopeButton(
                    label: 'Ma tâche',
                    icon: Icons.work_outline,
                    selected: _scope == 'doctor',
                    onTap: () => setState(() => _scope = 'doctor'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ScopeButton(
                    label: 'Patient',
                    icon: Icons.person_outline,
                    selected: _scope == 'patient',
                    onTap: () => setState(() => _scope = 'patient'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Titre
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titre *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description (optionnel)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),

            // Priorité + Catégorie
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: const InputDecoration(labelText: 'Priorité', border: OutlineInputBorder(), isDense: true),
                    items: {'LOW': 'Basse', 'MEDIUM': 'Moyenne', 'HIGH': 'Haute', 'URGENT': 'Urgent'}
                        .entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _priority = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Catégorie', border: OutlineInputBorder(), isDense: true),
                    items: _categoryLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Statut
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Statut', border: OutlineInputBorder(), isDense: true),
              items: _statusLabels.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 12),

            // Date d'échéance
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(
                _dueDate != null
                    ? 'Échéance : ${DateFormat('d MMM yyyy', 'fr_FR').format(_dueDate!)}'
                    : 'Ajouter une date d\'échéance',
                style: TextStyle(color: _dueDate != null ? Colors.black87 : Colors.grey[600]),
              ),
              trailing: _dueDate != null
                  ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _dueDate = null))
                  : null,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
            ),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving || _titleController.text.trim().isEmpty
                    ? null
                    : () async {
                        if (_titleController.text.trim().isEmpty) return;
                        setState(() => _saving = true);
                        await widget.onSave({
                          'title': _titleController.text.trim(),
                          'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
                          'priority': _priority,
                          'category': _category,
                          'status': _status,
                          'dueDate': _dueDate?.toIso8601String(),
                          'patientId': null, // TODO: patient search
                          'tags': [],
                        });
                        if (mounted) setState(() => _saving = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isEditing ? 'Enregistrer' : 'Créer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ScopeButton({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? const Color(0xFF0D9488) : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: selected ? const Color(0xFF0D9488).withValues(alpha: 0.08) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? const Color(0xFF0D9488) : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? const Color(0xFF0D9488) : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
