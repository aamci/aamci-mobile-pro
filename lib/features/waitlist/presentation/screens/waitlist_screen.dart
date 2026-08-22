import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/waitlist_provider.dart';

const _statusLabels = {
  'ACTIVE': 'Actif',
  'NOTIFIED': 'Notifié',
  'BOOKED': 'Réservé',
  'EXPIRED': 'Expiré',
};

const _statusColors = {
  'ACTIVE': Color(0xFF0D9488),
  'NOTIFIED': Color(0xFFF59E0B),
  'BOOKED': Color(0xFF16A34A),
  'EXPIRED': Color(0xFF6B7280),
};

class WaitlistScreen extends ConsumerStatefulWidget {
  const WaitlistScreen({super.key});

  @override
  ConsumerState<WaitlistScreen> createState() => _WaitlistScreenState();
}

class _WaitlistScreenState extends ConsumerState<WaitlistScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(waitlistProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(waitlistProvider);

    // Group entries by date
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final entry in state.entries) {
      final raw = entry['date'] as String?;
      final dateKey = raw != null
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(raw))
          : 'Sans date';
      grouped.putIfAbsent(dateKey, () => []).add(entry);
    }
    final sortedDates = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste d\'attente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.read(waitlistProvider.notifier).load(),
          ),
        ],
      ),
      body: Builder(builder: (context) {
        if (state.isLoading && state.entries.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null && state.entries.isEmpty) {
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
                  onPressed: () => ref.read(waitlistProvider.notifier).load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (state.entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.hourglass_empty, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Liste d\'attente vide',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucun patient en attente pour le moment',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(waitlistProvider.notifier).load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, i) {
              final dateKey = sortedDates[i];
              final dayEntries = grouped[dateKey]!;
              // Sort by position
              dayEntries.sort((a, b) =>
                  ((a['position'] as int?) ?? 0).compareTo((b['position'] as int?) ?? 0));

              DateTime? parsedDate;
              try {
                parsedDate = DateTime.parse(dateKey);
              } catch (_) {}

              final dateLabel = parsedDate != null
                  ? DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(parsedDate)
                  : dateKey;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (i > 0) const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Color(0xFF0D9488)),
                      const SizedBox(width: 6),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF0D9488),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${dayEntries.length} patient${dayEntries.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...dayEntries.map((entry) => _WaitlistEntryCard(
                        entry: entry,
                        onDelete: () => _confirmDelete(entry),
                      )),
                ],
              );
            },
          ),
        );
      }),
    );
  }

  void _confirmDelete(Map<String, dynamic> entry) {
    final patient = entry['patient'] as Map<String, dynamic>?;
    final name = patient?['fullName'] ?? 'ce patient';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer de la liste ?'),
        content: Text('Voulez-vous retirer "$name" de la liste d\'attente ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref.read(waitlistProvider.notifier).deleteEntry(entry['id']);
              if (!ok && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erreur lors de la suppression'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Retirer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _WaitlistEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onDelete;

  const _WaitlistEntryCard({required this.entry, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final patient = entry['patient'] as Map<String, dynamic>?;
    final position = entry['position'] as int? ?? 0;
    final status = entry['status'] as String? ?? 'ACTIVE';
    final statusColor = _statusColors[status] ?? const Color(0xFF6B7280);
    final statusLabel = _statusLabels[status] ?? status;
    final name = patient?['fullName'] as String? ?? 'Patient';
    final email = patient?['email'] as String?;
    final phone = patient?['phone'] as String?;
    final notifiedAt = entry['notifiedAt'] as String?;

    return Dismissible(
      key: Key(entry['id'] as String),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // We handle deletion ourselves
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Position badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$position',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: statusColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Patient info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    if (email != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 12, color: Color(0xFF6B7280)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (phone != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF6B7280)),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ],
                    if (notifiedAt != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_outlined,
                              size: 12, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Text(
                            'Notifié le ${DateFormat('d MMM HH:mm', 'fr_FR').format(DateTime.parse(notifiedAt))}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Status badge + delete button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.close, size: 16, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
