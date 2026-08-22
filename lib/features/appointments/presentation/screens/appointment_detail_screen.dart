import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/appointment_model.dart';
import '../providers/appointments_provider.dart';

class AppointmentDetailScreen extends ConsumerWidget {
  final AppointmentModel appointment;

  const AppointmentDetailScreen({super.key, required this.appointment});

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
      case 'CONFIRMED':  return const Color(0xFF22C55E);
      case 'PENDING':    return const Color(0xFFF59E0B);
      case 'CANCELLED':  return const Color(0xFFEF4444);
      case 'COMPLETED':  return const Color(0xFF0D9488);
      case 'NO_SHOW':    return const Color(0xFF9333EA);
      default:           return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slot    = appointment.slot;
    final patient = appointment.patient;
    final dateStr = slot != null
        ? DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(slot.start)
        : '—';
    final timeStr = slot != null
        ? '${DateFormat('HH:mm').format(slot.start)} – ${DateFormat('HH:mm').format(slot.end)}'
        : '—';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du rendez-vous'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Patient card
          _Section(
            title: 'Patient',
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  child: Text(
                    (patient?.fullName ?? patient?.email ?? '?').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF0D9488),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient?.fullName ?? 'Patient',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                      if (patient?.email != null)
                        Text(patient!.email, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                if (patient != null)
                  IconButton(
                    icon: const Icon(Icons.folder_open_outlined),
                    tooltip: 'Voir le dossier',
                    onPressed: () => context.push('/patient/${patient.id}'),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Date & heure
          _Section(
            title: 'Date et heure',
            child: Column(
              children: [
                _InfoRow(icon: Icons.calendar_today, label: 'Date', value: dateStr),
                const SizedBox(height: 8),
                _InfoRow(icon: Icons.access_time, label: 'Heure', value: timeStr),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Type & statut
          _Section(
            title: 'Consultation',
            child: Column(
              children: [
                _InfoRow(
                  icon: _isVisio ? Icons.videocam : Icons.medical_services_outlined,
                  label: 'Type',
                  value: appointment.kind?.name ?? appointment.type,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 10),
                    const Text('Statut', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor(appointment.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        appointment.statusLabel,
                        style: TextStyle(
                          color: _statusColor(appointment.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                if (appointment.kind?.durationMins != null && appointment.kind!.durationMins > 0) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.timer_outlined,
                    label: 'Durée',
                    value: '${appointment.kind!.durationMins} min',
                  ),
                ],
              ],
            ),
          ),

          if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _Section(
              title: 'Notes',
              child: Text(appointment.notes!, style: const TextStyle(fontSize: 14)),
            ),
          ],

          const SizedBox(height: 20),

          // Actions
          if (appointment.status == 'PENDING') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _changeStatus(context, ref, 'CANCELLED'),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Refuser'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _changeStatus(context, ref, 'CONFIRMED'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Confirmer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (appointment.status == 'CONFIRMED') ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _changeStatus(context, ref, 'NO_SHOW'),
                    icon: const Icon(Icons.person_off_outlined, size: 16),
                    label: const Text('Absent'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9333EA),
                      side: const BorderSide(color: Color(0xFF9333EA)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _changeStatus(context, ref, 'COMPLETED'),
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Terminé'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            if (_isVisio) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push(
                    '/teleconsultation/${appointment.id}',
                    extra: {'patientName': patient?.fullName ?? patient?.email},
                  ),
                  icon: const Icon(Icons.videocam, size: 18),
                  label: const Text('Rejoindre la visio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: 12),

          // Voir dossier patient
          if (patient != null)
            OutlinedButton.icon(
              onPressed: () => context.push('/patient/${patient.id}'),
              icon: const Icon(Icons.folder_open_outlined, size: 16),
              label: const Text('Voir le dossier patient'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _changeStatus(BuildContext context, WidgetRef ref, String newStatus) async {
    final success = await ref.read(appointmentsProvider.notifier).updateStatus(appointment.id, newStatus);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Statut mis à jour' : 'Erreur lors de la mise à jour'),
      backgroundColor: success ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
    ));
    if (success) context.pop();
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: Colors.grey, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      ],
    );
  }
}
