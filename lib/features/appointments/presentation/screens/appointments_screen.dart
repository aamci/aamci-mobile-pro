import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/models/appointment_model.dart';
import '../providers/appointments_provider.dart';
import '../../../../core/widgets/app_empty_state.dart';

const _primary = Color(0xFF16A34A);

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _calendarMode = false;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

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

  // Regroupe tous les rdv par date locale (sans heure)
  Map<DateTime, List<AppointmentModel>> _buildEventMap(List<AppointmentModel> all) {
    final map = <DateTime, List<AppointmentModel>>{};
    for (final apt in all) {
      if (apt.slot == null) continue;
      final day = DateTime(apt.slot!.start.year, apt.slot!.start.month, apt.slot!.start.day);
      map.putIfAbsent(day, () => []).add(apt);
    }
    return map;
  }

  List<AppointmentModel> _eventsForDay(Map<DateTime, List<AppointmentModel>> map, DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return map[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appointmentsProvider);
    final allApts = [...state.upcoming, ...state.past];
    final eventMap = _buildEventMap(allApts);
    final selectedEvents = _eventsForDay(eventMap, _selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendez-vous'),
        actions: [
          IconButton(
            icon: Icon(_calendarMode ? Icons.list_rounded : Icons.calendar_month_rounded),
            tooltip: _calendarMode ? 'Vue liste' : 'Vue calendrier',
            onPressed: () => setState(() => _calendarMode = !_calendarMode),
          ),
        ],
        bottom: _calendarMode
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'À venir'),
                  Tab(text: 'Historique'),
                ],
              ),
      ),
      body: state.isLoading && allApts.isEmpty
          ? _AppointmentsSkeleton()
          : _calendarMode
              ? _CalendarView(
                  focusedDay: _focusedDay,
                  selectedDay: _selectedDay,
                  eventMap: eventMap,
                  selectedEvents: selectedEvents,
                  onDaySelected: (selected, focused) =>
                      setState(() { _selectedDay = selected; _focusedDay = focused; }),
                  onStatusChange: _updateStatus,
                  onRefresh: () => ref.read(appointmentsProvider.notifier).load(),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _AppointmentList(
                      appointments: state.upcoming,
                      emptyMessage: 'Aucun rendez-vous à venir',
                      emptySubtitle: 'Les nouvelles demandes apparaîtront ici',
                      emptyIcon: Icons.event_note_outlined,
                      onRefresh: () => ref.read(appointmentsProvider.notifier).load(),
                      onStatusChange: _updateStatus,
                    ),
                    _AppointmentList(
                      appointments: state.past,
                      emptyMessage: 'Aucun historique',
                      emptySubtitle: 'Vos consultations passées apparaîtront ici',
                      emptyIcon: Icons.history_rounded,
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

// ─── Vue Calendrier ───────────────────────────────────────────────────────────

class _CalendarView extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Map<DateTime, List<AppointmentModel>> eventMap;
  final List<AppointmentModel> selectedEvents;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(String, String)? onStatusChange;
  final Future<void> Function() onRefresh;

  const _CalendarView({
    required this.focusedDay,
    required this.selectedDay,
    required this.eventMap,
    required this.selectedEvents,
    required this.onDaySelected,
    required this.onRefresh,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedLabel = DateFormat('EEEE d MMMM', 'fr_FR').format(selectedDay);
    final labelCap = selectedLabel[0].toUpperCase() + selectedLabel.substring(1);

    return Column(
      children: [
        TableCalendar<AppointmentModel>(
          locale: 'fr_FR',
          firstDay: DateTime.utc(2023, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(day, selectedDay),
          eventLoader: (day) {
            final key = DateTime(day.year, day.month, day.day);
            return eventMap[key] ?? [];
          },
          onDaySelected: onDaySelected,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Mois'},
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          calendarStyle: CalendarStyle(
            selectedDecoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
            todayDecoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            todayTextStyle: const TextStyle(color: _primary, fontWeight: FontWeight.w700),
            markerDecoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
            markersMaxCount: 3,
            markerSize: 5,
            markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
            outsideDaysVisible: false,
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                labelCap,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${selectedEvents.length} rdv',
                  style: const TextStyle(color: _primary, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: selectedEvents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available, size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun rendez-vous ce jour',
                        style: TextStyle(color: Colors.grey[600], fontSize: 15),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: selectedEvents.length,
                    itemBuilder: (context, index) => _AppointmentCard(
                      appointment: selectedEvents[index],
                      onStatusChange: onStatusChange,
                    )
                        .animate()
                        .fadeIn(duration: 250.ms, delay: (index * 50).ms)
                        .slideY(begin: 0.04, curve: Curves.easeOut),
                  ),
                ),
        ),
      ],
    );
  }
}

class _AppointmentsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final String emptyMessage;
  final String emptySubtitle;
  final IconData emptyIcon;
  final Future<void> Function() onRefresh;
  final void Function(String, String)? onStatusChange;

  const _AppointmentList({
    required this.appointments,
    required this.emptyMessage,
    required this.emptySubtitle,
    required this.emptyIcon,
    required this.onRefresh,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return AppEmptyState(icon: emptyIcon, title: emptyMessage, subtitle: emptySubtitle);
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
          )
              .animate()
              .fadeIn(duration: 300.ms, delay: (index * 60).ms)
              .slideY(begin: 0.05, curve: Curves.easeOut);
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
        return const Color(0xFF0D9488);
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
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => context.push('/appointments/${appointment.id}', extra: appointment),
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
                  child: Text(
                    (patient?.fullName ?? '?').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF0D9488),
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
      ),
    );
  }
}
