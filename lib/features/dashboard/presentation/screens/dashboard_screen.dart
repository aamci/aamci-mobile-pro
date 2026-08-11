import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../data/models/stats_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboard = ref.watch(dashboardProvider);
    final userName = authState.user?.fullName ?? 'Docteur';
    final stats = dashboard.stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour, Dr. $userName',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              if (dashboard.isLoading && stats == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.calendar_today,
                        label: 'RDV à venir',
                        value: '${stats?.upcomingAppointments ?? 0}',
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle,
                        label: 'Confirmés ce mois',
                        value: '${stats?.confirmedThisMonth ?? 0}',
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.account_balance_wallet,
                        label: 'Revenus ce mois',
                        value: stats != null
                            ? '${stats.revenueThisMonth.toStringAsFixed(0)} F'
                            : '0 F',
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.event_busy,
                        label: 'Total RDV',
                        value: '${stats?.totalAppointments ?? 0}',
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Accès rapide',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.task_alt_outlined,
                      label: 'Tâches',
                      color: const Color(0xFF0D9488),
                      onTap: () => context.push('/tasks'),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.swap_horiz_outlined,
                      label: 'Adressages',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => context.push('/referrals'),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.chat_bubble_outline,
                      label: 'Messages',
                      color: const Color(0xFF2563EB),
                      onTap: () => context.push('/messages'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.hourglass_top_outlined,
                      label: 'Liste attente',
                      color: const Color(0xFF0D9488),
                      onTap: () => context.push('/waitlist'),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.quiz_outlined,
                      label: 'Formulaires',
                      color: const Color(0xFFF59E0B),
                      onTap: () => context.push('/questionnaires'),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Prochains rendez-vous',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                if (dashboard.nextAppointments.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Aucun rendez-vous à venir',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    ),
                  )
                else
                  ...dashboard.nextAppointments.map((apt) => _NextAppointmentCard(apt: apt)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextAppointmentCard extends StatelessWidget {
  final NextAppointment apt;

  const _NextAppointmentCard({required this.apt});

  bool get _isVisio {
    final name = (apt.kindName ?? '').toLowerCase();
    return name.contains('visio') ||
        name.contains('téléconsultation') ||
        name.contains('teleconsultation') ||
        name.contains('video') ||
        name.contains('vidéo');
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _isVisio
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                  : const Color(0xFF2563EB).withValues(alpha: 0.1),
              child: Text(
                (apt.patientName ?? '?').substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: _isVisio ? const Color(0xFF7C3AED) : const Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apt.patientName ?? apt.patientEmail ?? 'Patient',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    apt.slotStart != null
                        ? '${DateFormat('EEE d MMM', 'fr_FR').format(apt.slotStart!)} à ${DateFormat('HH:mm').format(apt.slotStart!)}'
                        : '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  if (apt.kindName != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (_isVisio) ...[
                          const Icon(Icons.videocam, size: 13, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          apt.kindName!,
                          style: TextStyle(
                            color: _isVisio ? const Color(0xFF7C3AED) : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (_isVisio)
              ElevatedButton.icon(
                onPressed: () => context.push(
                  '/teleconsultation/${apt.id}',
                  extra: {'patientName': apt.patientName ?? apt.patientEmail},
                ),
                icon: const Icon(Icons.videocam, size: 16),
                label: const Text('Rejoindre', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
