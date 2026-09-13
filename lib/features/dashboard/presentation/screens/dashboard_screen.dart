import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../data/models/stats_model.dart';

// Permet l'overscroll en haut (pull-to-refresh) mais bloque en bas
class _ClampBottomPhysics extends ScrollPhysics {
  const _ClampBottomPhysics({super.parent});

  @override
  _ClampBottomPhysics applyTo(ScrollPhysics? ancestor) =>
      _ClampBottomPhysics(parent: buildParent(ancestor));

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value > position.maxScrollExtent) {
      return value - position.maxScrollExtent;
    }
    return 0.0;
  }
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const _primary = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(dashboardProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboard = ref.watch(dashboardProvider);
    final rawName = authState.user?.fullName ?? 'Docteur';
    final userName = rawName.toLowerCase().startsWith('dr') ? rawName : 'Dr. $rawName';
    final stats = dashboard.stats;
    final isLoading = dashboard.isLoading && stats == null;

    final rawDate = DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now());
    final dateStr = rawDate[0].toUpperCase() + rawDate.substring(1);

    final bodyBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: _primary,
      body: RefreshIndicator(
        color: _primary,
        onRefresh: () => ref.read(dashboardProvider.notifier).load(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: _ClampBottomPhysics()),
          slivers: [
            // ─── Header vert ─────────────────────────────────────
            SliverToBoxAdapter(
              child: _ProHeader(userName: userName, dateStr: dateStr),
            ),

            // ─── Body blanc ───────────────────────────────────────
            SliverToBoxAdapter(
              child: ColoredBox(
                color: bodyBg,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: isLoading
                      ? const _DashboardSkeleton()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stats
                            _StatsGrid(stats: stats)
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.06, curve: Curves.easeOut),

                            const SizedBox(height: 24),

                            // Quick actions
                            Text(
                              'Accès rapide',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ).animate().fadeIn(duration: 350.ms, delay: 80.ms),
                            const SizedBox(height: 12),
                            const _QuickActionsGrid()
                                .animate()
                                .fadeIn(duration: 400.ms, delay: 120.ms)
                                .slideY(begin: 0.06, curve: Curves.easeOut),

                            const SizedBox(height: 24),

                            // Next appointments
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Prochains rendez-vous',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/appointments'),
                                  child: const Text(
                                    'Tout voir',
                                    style: TextStyle(fontSize: 13, color: _primary, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(duration: 350.ms, delay: 180.ms),
                            const SizedBox(height: 12),

                            if (dashboard.nextAppointments.isEmpty)
                              _EmptyAppointmentsCard()
                                  .animate()
                                  .fadeIn(duration: 400.ms, delay: 220.ms)
                            else
                              ...dashboard.nextAppointments.asMap().entries.map(
                                (e) => _NextAppointmentCard(apt: e.value)
                                    .animate()
                                    .fadeIn(duration: 350.ms, delay: (220 + e.key * 60).ms)
                                    .slideY(begin: 0.05, curve: Curves.easeOut),
                              ),
                          ],
                        ),
                ),
              ),
            ),

            // ─── Remplit l'espace restant en blanc (pas de scroll supplémentaire) ─
            SliverFillRemaining(
              hasScrollBody: false,
              child: ColoredBox(color: bodyBg),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _ProHeader extends ConsumerWidget {
  final String userName;
  final String dateStr;

  const _ProHeader({required this.userName, required this.dateStr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotifCountProvider).valueOrNull ?? 0;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bonjour,',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Badge(
                isLabelVisible: unreadCount > 0,
                label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                    onPressed: () => context.push('/notifications'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade100,
      highlightColor: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              4,
              (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(width: 120, height: 16, decoration: _pill()),
          const SizedBox(height: 12),
          // Quick actions skeleton
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(
              6,
              (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(width: 180, height: 16, decoration: _pill()),
          const SizedBox(height: 12),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _pill() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
  );
}

// ─── Stats grid ───────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final DoctorStats? stats;

  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.calendar_today_rounded, 'RDV à venir', '${stats?.upcomingAppointments ?? 0}', const Color(0xFF16A34A)),
      (Icons.check_circle_outline_rounded, 'Confirmés ce mois', '${stats?.confirmedThisMonth ?? 0}', const Color(0xFF22C55E)),
      (Icons.account_balance_wallet_outlined, 'Revenus du mois', '${stats?.revenueThisMonth.toStringAsFixed(0) ?? '0'} F', const Color(0xFFF59E0B)),
      (Icons.people_outline_rounded, 'Total RDV', '${stats?.totalAppointments ?? 0}', const Color(0xFF8B5CF6)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: items
          .map((item) => _StatCard(icon: item.$1, label: item.$2, value: item.$3, color: item.$4))
          .toList(),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Quick actions ────────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const _primary = Color(0xFF16A34A);

  @override
  Widget build(BuildContext context) {
    final actions = [
      (Icons.event_note_rounded, 'Agenda', _primary, () => context.go('/planning')),
      (Icons.people_rounded, 'Patients', const Color(0xFF0EA5E9), () => context.go('/patients')),
      (Icons.chat_bubble_outline_rounded, 'Messages', const Color(0xFF22C55E), () => context.push('/messages')),
      (Icons.swap_horiz_rounded, 'Adressages', const Color(0xFF8B5CF6), () => context.push('/referrals')),
      (Icons.hourglass_top_rounded, 'Attente', const Color(0xFFF59E0B), () => context.push('/waitlist')),
      (Icons.quiz_outlined, 'Formulaires', const Color(0xFFEC4899), () => context.push('/questionnaires')),
    ];

    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: actions
          .asMap()
          .entries
          .map(
            (e) => _QuickActionCard(
              icon: e.value.$1,
              label: e.value.$2,
              color: e.value.$3,
              onTap: e.value.$4,
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: (120 + e.key * 40).ms)
                .scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOut),
          )
          .toList(),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyAppointmentsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.12)),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.event_available_outlined, size: 36, color: Color(0xFF16A34A)),
            const SizedBox(height: 10),
            Text(
              'Aucun rendez-vous à venir',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Next appointment card ────────────────────────────────────────────────────

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

  String get _initial {
    final name = apt.patientName ?? apt.patientEmail ?? '?';
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _isVisio ? const Color(0xFF7C3AED) : const Color(0xFF16A34A);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: accentColor.withValues(alpha: 0.1),
            child: Text(
              _initial,
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
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
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (_isVisio) ...[
                      Icon(Icons.videocam_rounded, size: 13, color: accentColor),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      apt.kindName ?? 'Consultation',
                      style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                if (apt.slotStart != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${DateFormat('EEE d MMM', 'fr_FR').format(apt.slotStart!)} · ${DateFormat('HH:mm').format(apt.slotStart!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color(0xFF94A3B8)),
                  ),
                ],
              ],
            ),
          ),
          if (_isVisio)
            FilledButton.icon(
              onPressed: () => context.push(
                '/teleconsultation/${apt.id}',
                extra: {'patientName': apt.patientName ?? apt.patientEmail},
              ),
              icon: const Icon(Icons.videocam_rounded, size: 15),
              label: const Text('Rejoindre', style: TextStyle(fontSize: 12)),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }
}
