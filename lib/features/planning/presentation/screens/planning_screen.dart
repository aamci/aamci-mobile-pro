import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/planning_provider.dart';
import '../../../appointments/presentation/providers/appointments_provider.dart';
import '../../../appointments/data/models/appointment_model.dart';

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appointmentsProvider.notifier).load();
    });
  }

  List<AppointmentModel> _appointmentsForDay(List<AppointmentModel> all, DateTime day) {
    return all.where((a) {
      final start = a.slot?.start;
      if (start == null) return false;
      return start.year == day.year && start.month == day.month && start.day == day.day;
    }).toList()
      ..sort((a, b) => (a.slot?.start ?? a.createdAt).compareTo(b.slot?.start ?? b.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(myRulesProvider);
    final apptState = ref.watch(appointmentsProvider);
    final dayAppts = _appointmentsForDay(apptState.appointments, _selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule),
            tooltip: 'Gérer les disponibilités',
            onPressed: () => context.push('/availability-rules'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/availability-rules'),
        icon: const Icon(Icons.add),
        label: const Text('Disponibilités'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar(
            locale: 'fr_FR',
            firstDay: DateTime.now().subtract(const Duration(days: 60)),
            lastDay: DateTime.now().add(const Duration(days: 180)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: CalendarFormat.week,
            availableCalendarFormats: const {
              CalendarFormat.week: 'Semaine',
              CalendarFormat.month: 'Mois',
            },
            eventLoader: (day) {
              return _appointmentsForDay(apptState.appointments, day);
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final rules = rulesAsync.valueOrNull ?? [];
                final dayOfWeek = day.weekday;
                final hasRule = rules.any((r) =>
                    r.status == 'ACTIVE' &&
                    r.daysOfWeek.contains(dayOfWeek) &&
                    day.isAfter(r.startDate.subtract(const Duration(days: 1))) &&
                    day.isBefore(r.endDate.add(const Duration(days: 1))));
                if (!hasRule) return null;
                return Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                );
              },
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                return Positioned(
                  bottom: 4,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
            startingDayOfWeek: StartingDayOfWeek.monday,
          ),

          const Divider(height: 1),

          // Day header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  DateFormat('EEEE d MMMM', 'fr_FR').format(_selectedDay),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const Spacer(),
                if (dayAppts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${dayAppts.length} RDV',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Appointments list
          Expanded(
            child: apptState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : dayAppts.isEmpty
                    ? _EmptyDay(day: _selectedDay)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: dayAppts.length,
                        itemBuilder: (context, i) => _DayAppointmentCard(appointment: dayAppts[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  final DateTime day;
  const _EmptyDay({required this.day});

  @override
  Widget build(BuildContext context) {
    final isToday = isSameDay(day, DateTime.now());
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            isToday ? 'Aucun rendez-vous aujourd\'hui' : 'Aucun rendez-vous ce jour',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Journée libre',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _DayAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  const _DayAppointmentCard({required this.appointment});

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
  Widget build(BuildContext context) {
    final slot = appointment.slot;
    final timeStr = slot != null
        ? DateFormat('HH:mm').format(slot.start)
        : '--:--';
    final endStr = slot != null
        ? DateFormat('HH:mm').format(slot.end)
        : '';
    final patient = appointment.patient;
    final name = patient?.fullName ?? patient?.email ?? 'Patient';
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    final color = _statusColor(appointment.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/appointments/${appointment.id}', extra: appointment),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Time column
              SizedBox(
                width: 52,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(timeStr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text(endStr, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              // Patient info
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(initials, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                      appointment.kind?.name ?? appointment.type,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appointment.statusLabel,
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
