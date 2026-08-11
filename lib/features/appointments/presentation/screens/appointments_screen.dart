import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/appointment_model.dart';
import '../providers/appointments_provider.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(appointmentsProvider.notifier).load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendez-vous'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'À venir'),
            Tab(text: 'Historique'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _AppointmentList(
                  appointments: state.upcoming,
                  emptyMessage: 'Aucun rendez-vous à venir',
                  emptyIcon: Icons.event_note,
                  onRefresh: () => ref.read(appointmentsProvider.notifier).load(),
                  onStatusChange: _updateStatus,
                ),
                _AppointmentList(
                  appointments: state.past,
                  emptyMessage: 'Aucun historique',
                  emptyIcon: Icons.history,
                  onRefresh: () => ref.read(appointmentsProvider.notifier).load(),
                ),
              ],
            ),
    );
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    final success = await ref.read(appointmentsProvider.notifier).updateStatus(id, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Statut mis à jour' : 'Erreur'),
      backgroundColor: success ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
    ));
  }
}

class _AppointmentList extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final String emptyMessage;
  final IconData emptyIcon;
  final Future<void> Function() onRefresh;
  final void Function(String, String)? onStatusChange;

  const _AppointmentList({
    required this.appointments,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onRefresh,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(emptyMessage, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          return _AppointmentCard(
            appointment: appointments[index],
            onStatusChange: onStatusChange,
          );
        },
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final void Function(String, String)? onStatusChange;

  const _AppointmentCard({required this.appointment, this.onStatusChange});

  bool get _isVisio {
    final name = (appointment.kind?.name ?? appointment.type).toLowerCase();
    return name.contains('visio') ||
        name.contains('téléconsultation') ||
        name.contains('teleconsultation') ||
        name.contains('video') ||
        name.contains('vidéo');
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return const Color(0xFF22C55E);
      case 'PENDING':
        return const Color(0xFFF59E0B);
      case 'CANCELLED':
        return const Color(0xFFEF4444);
      case 'COMPLETED':
        return const Color(0xFF2563EB);
      case 'NO_SHOW':
        return const Color(0xFF9333EA);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final slot = appointment.slot;
    final patient = appointment.patient;
    final dateStr = slot != null
        ? DateFormat('EEE d MMM yyyy', 'fr_FR').format(slot.start)
        : '';
    final timeStr = slot != null
        ? '${DateFormat('HH:mm').format(slot.start)} - ${DateFormat('HH:mm').format(slot.end)}'
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  child: Text(
                    (patient?.fullName ?? '?').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
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
                        patient?.fullName ?? patient?.email ?? 'Patient',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      if (appointment.kind != null)
                        Text(
                          appointment.kind!.name,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(appointment.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    appointment.statusLabel,
                    style: TextStyle(
                      color: _statusColor(appointment.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (slot != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 6),
                  Text(dateStr, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 14),
                  const SizedBox(width: 6),
                  Text(timeStr, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ],
            if (onStatusChange != null && appointment.status == 'PENDING') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => onStatusChange!(appointment.id, 'CANCELLED'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Refuser'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => onStatusChange!(appointment.id, 'CONFIRMED'),
                    child: const Text('Confirmer'),
                  ),
                ],
              ),
            ],
            if (onStatusChange != null && appointment.status == 'CONFIRMED') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => onStatusChange!(appointment.id, 'NO_SHOW'),
                    child: const Text('Absent'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => onStatusChange!(appointment.id, 'COMPLETED'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
                    child: const Text('Terminé'),
                  ),
                ],
              ),
            ],
            if (_isVisio && appointment.status == 'CONFIRMED') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push(
                    '/teleconsultation/${appointment.id}',
                    extra: {
                      'patientName': appointment.patient?.fullName ??
                          appointment.patient?.email,
                    },
                  ),
                  icon: const Icon(Icons.videocam, size: 18),
                  label: const Text('Rejoindre la visio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
