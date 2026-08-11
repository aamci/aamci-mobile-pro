import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/referrals_provider.dart';

const _urgencyColors = {
  'LOW': Color(0xFF6B7280),
  'NORMAL': Color(0xFF2563EB),
  'HIGH': Color(0xFFF97316),
  'URGENT': Color(0xFFDC2626),
};
const _urgencyLabels = {
  'LOW': 'Faible',
  'NORMAL': 'Normal',
  'HIGH': 'Haute',
  'URGENT': 'Urgent',
};
const _statusColors = {
  'PENDING': Color(0xFFF59E0B),
  'ACCEPTED': Color(0xFF16A34A),
  'REJECTED': Color(0xFFDC2626),
  'COMPLETED': Color(0xFF6B7280),
};
const _statusLabels = {
  'PENDING': 'En attente',
  'ACCEPTED': 'Accepté',
  'REJECTED': 'Refusé',
  'COMPLETED': 'Terminé',
};

class ReferralsScreen extends ConsumerStatefulWidget {
  const ReferralsScreen({super.key});

  @override
  ConsumerState<ReferralsScreen> createState() => _ReferralsScreenState();
}

class _ReferralsScreenState extends ConsumerState<ReferralsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() => ref.read(referralsProvider.notifier).load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(referralsProvider);
    final pendingCount = state.received.where((r) => r['status'] == 'PENDING').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adressages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(referralsProvider.notifier).load(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Reçus'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Envoyés'),
            const Tab(text: 'Dossiers reçus'),
          ],
        ),
      ),
      body: state.isLoading && state.received.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _ReceivedTab(referrals: state.received),
                _SentTab(referrals: state.sent),
                _ReceivedPatientsTab(patients: state.receivedPatients),
              ],
            ),
    );
  }
}

// ─── Received Tab ───────────────────────────────────────────────────────────

class _ReceivedTab extends ConsumerWidget {
  final List<Map<String, dynamic>> referrals;
  const _ReceivedTab({required this.referrals});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (referrals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Aucun adressage reçu', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(referralsProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: referrals.length,
        itemBuilder: (context, i) => _ReceivedCard(referral: referrals[i]),
      ),
    );
  }
}

class _ReceivedCard extends ConsumerWidget {
  final Map<String, dynamic> referral;
  const _ReceivedCard({required this.referral});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = referral['status'] as String? ?? 'PENDING';
    final patient = referral['patient'] as Map<String, dynamic>?;
    final fromDoctor = referral['fromDoctor'] as Map<String, dynamic>?;
    final urgency = referral['urgency'] as String? ?? 'NORMAL';
    final isPending = status == 'PENDING';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPending ? const BorderSide(color: Color(0xFFF59E0B), width: 1.5) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  child: Text(
                    (patient?['fullName'] ?? '?').substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient?['fullName'] ?? 'Patient inconnu',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (fromDoctor != null)
                        Text(
                          'De : Dr ${fromDoctor['fullName'] ?? ''}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _UrgencyBadge(urgency: urgency),
                const SizedBox(width: 8),
                if (referral['createdAt'] != null)
                  Text(
                    DateFormat('d MMM yyyy', 'fr_FR').format(DateTime.parse(referral['createdAt'])),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
              ],
            ),
            if (referral['reason'] != null && (referral['reason'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  referral['reason'],
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
            if (referral['response'] != null && (referral['response'] as String).isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.reply, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Réponse : ${referral['response']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _respond(context, ref, false),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Refuser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                        side: const BorderSide(color: Color(0xFFDC2626)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _respond(context, ref, true),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accepter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (status == 'ACCEPTED') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => ref.read(referralsProvider.notifier).complete(referral['id']),
                  child: const Text('Marquer comme terminé'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _respond(BuildContext context, WidgetRef ref, bool accept) {
    final responseController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(accept ? 'Accepter l\'adressage' : 'Refuser l\'adressage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(accept
                ? 'Voulez-vous accepter ce patient ?'
                : 'Indiquez la raison du refus (optionnel)'),
            const SizedBox(height: 12),
            TextField(
              controller: responseController,
              decoration: const InputDecoration(
                hintText: 'Message (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(referralsProvider.notifier).respond(
                referral['id'],
                accept: accept,
                response: responseController.text.trim().isEmpty ? null : responseController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accept ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: Text(accept ? 'Accepter' : 'Refuser'),
          ),
        ],
      ),
    );
  }
}

// ─── Sent Tab ────────────────────────────────────────────────────────────────

class _SentTab extends ConsumerWidget {
  final List<Map<String, dynamic>> referrals;
  const _SentTab({required this.referrals});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (referrals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.send_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Aucun adressage envoyé', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(referralsProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: referrals.length,
        itemBuilder: (context, i) {
          final r = referrals[i];
          final patient = r['patient'] as Map<String, dynamic>?;
          final toDoctor = r['toDoctor'] as Map<String, dynamic>?;
          final status = r['status'] as String? ?? 'PENDING';
          final urgency = r['urgency'] as String? ?? 'NORMAL';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                        child: Text(
                          (patient?['fullName'] ?? '?').substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient?['fullName'] ?? 'Patient',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (toDoctor != null)
                              Text(
                                'Vers : Dr ${toDoctor['fullName'] ?? ''}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                          ],
                        ),
                      ),
                      _StatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _UrgencyBadge(urgency: urgency),
                      const SizedBox(width: 8),
                      if (r['createdAt'] != null)
                        Text(
                          DateFormat('d MMM yyyy', 'fr_FR').format(DateTime.parse(r['createdAt'])),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                  if (r['reason'] != null && (r['reason'] as String).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(r['reason'], style: const TextStyle(fontSize: 13)),
                  ],
                  if (r['response'] != null && (r['response'] as String).isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _statusColors[status]?.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.reply, size: 14, color: _statusColors[status]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              r['response'],
                              style: TextStyle(fontSize: 12, color: _statusColors[status]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Received Patients Tab ───────────────────────────────────────────────────

class _ReceivedPatientsTab extends ConsumerWidget {
  final List<Map<String, dynamic>> patients;
  const _ReceivedPatientsTab({required this.patients});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (patients.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Aucun dossier reçu', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(referralsProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: patients.length,
        itemBuilder: (context, i) {
          final r = patients[i];
          final patient = r['patient'] as Map<String, dynamic>?;
          final fromDoctor = r['fromDoctor'] as Map<String, dynamic>?;
          final status = r['status'] as String? ?? 'ACCEPTED';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.1),
                child: Text(
                  (patient?['fullName'] ?? '?').substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                patient?['fullName'] ?? 'Patient',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (fromDoctor != null)
                    Text('De : Dr ${fromDoctor['fullName'] ?? ''}', style: const TextStyle(fontSize: 12)),
                  if (r['respondedAt'] != null)
                    Text(
                      'Accepté le ${DateFormat('d MMM yyyy', 'fr_FR').format(DateTime.parse(r['respondedAt']))}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                ],
              ),
              trailing: _StatusBadge(status: status),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _statusLabels[status] ?? status,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _UrgencyBadge extends StatelessWidget {
  final String urgency;
  const _UrgencyBadge({required this.urgency});

  @override
  Widget build(BuildContext context) {
    final color = _urgencyColors[urgency] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _urgencyLabels[urgency] ?? urgency,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}
