import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String _selectedPeriod = '30d';

  static const Map<String, String> _periodLabels = {
    '7d': '7j',
    '30d': '30j',
    '90d': '90j',
    '12m': '12m',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dashboardAsync = ref.watch(analyticsDashboardProvider(_selectedPeriod));
    final trendsAsync = ref.watch(analyticsTrendsProvider);
    final topServicesAsync = ref.watch(analyticsTopServicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytique'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(analyticsDashboardProvider(_selectedPeriod));
          ref.invalidate(analyticsTrendsProvider);
          ref.invalidate(analyticsTopServicesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period selector
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: _periodLabels.entries
                      .map((e) => ButtonSegment<String>(
                            value: e.key,
                            label: Text(e.value),
                          ))
                      .toList(),
                  selected: {_selectedPeriod},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _selectedPeriod = selection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Dashboard KPI cards
              dashboardAsync.when(
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _buildErrorWidget(
                  'Impossible de charger les indicateurs',
                  () => ref.invalidate(analyticsDashboardProvider(_selectedPeriod)),
                ),
                data: (dashboard) => _buildKpiGrid(context, dashboard),
              ),
              const SizedBox(height: 32),

              // Trends section
              Text(
                'Tendances mensuelles',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              trendsAsync.when(
                loading: () => const SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _buildErrorWidget(
                  'Impossible de charger les tendances',
                  () => ref.invalidate(analyticsTrendsProvider),
                ),
                data: (trends) => _buildTrendsChart(context, trends),
              ),
              const SizedBox(height: 32),

              // Top services section
              Text(
                'Services populaires',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              topServicesAsync.when(
                loading: () => const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _buildErrorWidget(
                  'Impossible de charger les services',
                  () => ref.invalidate(analyticsTopServicesProvider),
                ),
                data: (services) => _buildTopServices(context, services),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, Map<String, dynamic> dashboard) {
    final kpis = [
      _KpiData(
        label: 'Rendez-vous',
        value: '${dashboard['totalAppointments'] ?? 0}',
        icon: Icons.calendar_today,
        color: Colors.blue,
      ),
      _KpiData(
        label: 'Revenus',
        value: '${dashboard['totalRevenue'] ?? 0} FCFA',
        icon: Icons.attach_money,
        color: Colors.green,
      ),
      _KpiData(
        label: 'Note moyenne',
        value: _formatRating(dashboard['averageRating']),
        icon: Icons.star,
        color: Colors.orange,
      ),
      _KpiData(
        label: 'Nouveaux patients',
        value: '${dashboard['newPatients'] ?? 0}',
        icon: Icons.person_add,
        color: Colors.purple,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: kpis.length,
      itemBuilder: (context, index) => _buildKpiCard(context, kpis[index]),
    );
  }

  Widget _buildKpiCard(BuildContext context, _KpiData kpi) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kpi.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(kpi.icon, color: kpi.color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            kpi.value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            kpi.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsChart(BuildContext context, List<Map<String, dynamic>> trends) {
    if (trends.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('Aucune donnée disponible')),
      );
    }

    final theme = Theme.of(context);
    final maxRevenue = trends.fold<double>(
      0,
      (max, item) => ((item['revenue'] as num?)?.toDouble() ?? 0) > max
          ? (item['revenue'] as num).toDouble()
          : max,
    );

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxRevenue > 0 ? maxRevenue * 1.2 : 100,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month = trends[group.x.toInt()]['month'] ?? '';
                final revenue = rod.toY.toInt();
                return BarTooltipItem(
                  '$month\n$revenue FCFA',
                  TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= trends.length) {
                    return const SizedBox.shrink();
                  }
                  final month = (trends[index]['month'] ?? '').toString();
                  final label = month.length >= 3 ? month.substring(0, 3) : month;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatCompact(value),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxRevenue > 0 ? maxRevenue / 4 : 25,
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(trends.length, (index) {
            final revenue = (trends[index]['revenue'] as num?)?.toDouble() ?? 0;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: revenue,
                  color: theme.colorScheme.primary,
                  width: 16,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTopServices(BuildContext context, List<Map<String, dynamic>> services) {
    if (services.isEmpty) {
      return const Center(child: Text('Aucun service disponible'));
    }

    final maxCount = services.fold<int>(
      0,
      (max, item) => ((item['count'] as num?)?.toInt() ?? 0) > max
          ? (item['count'] as num).toInt()
          : max,
    );

    return Column(
      children: services.map((service) {
        final name = service['name'] ?? 'Service';
        final count = (service['count'] as num?)?.toInt() ?? 0;
        final progress = maxCount > 0 ? count / maxCount : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name.toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '$count',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                  backgroundColor: Colors.grey.shade200,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorWidget(String message, VoidCallback onRetry) {
    return SizedBox(
      height: 150,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 36),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRating(dynamic rating) {
    if (rating == null) return '0.0';
    if (rating is num) return rating.toStringAsFixed(1);
    return rating.toString();
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toInt().toString();
  }
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}
