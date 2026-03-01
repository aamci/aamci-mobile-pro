import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/planning_provider.dart';
import '../../data/models/availability_rule_model.dart';

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(myRulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning'),
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'fr_FR',
            firstDay: DateTime.now().subtract(const Duration(days: 30)),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
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
                if (hasRule) {
                  return Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
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
                }
                return null;
              },
            ),
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            startingDayOfWeek: StartingDayOfWeek.monday,
          ),
          const Divider(),
          Expanded(
            child: rulesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (rules) {
                if (rules.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.schedule, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune règle de disponibilité',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Configurez vos horaires depuis le profil',
                          style: TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rules.length,
                  itemBuilder: (context, index) => _RuleCard(rule: rules[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final AvailabilityRuleModel rule;

  const _RuleCard({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: rule.status == 'ACTIVE'
                      ? const Color(0xFF22C55E)
                      : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  rule.daysLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: rule.status == 'ACTIVE'
                        ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rule.status == 'ACTIVE' ? 'Actif' : 'Inactif',
                    style: TextStyle(
                      fontSize: 12,
                      color: rule.status == 'ACTIVE'
                          ? const Color(0xFF22C55E)
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${rule.hoursLabel} • Créneaux de ${rule.slotDurationMins} min',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            if (rule.excludedTimes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Pauses: ${rule.excludedTimes.join(', ')}',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
