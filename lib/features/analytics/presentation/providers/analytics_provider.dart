import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/analytics_remote_datasource.dart';

final analyticsRemoteProvider = Provider<AnalyticsRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnalyticsRemoteDatasource(apiClient);
});

final analyticsDashboardProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, period) async {
  final datasource = ref.watch(analyticsRemoteProvider);
  return datasource.getDashboard(period: period);
});

final analyticsTrendsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(analyticsRemoteProvider);
  final data = await datasource.getTrends();
  return data.map((e) => e as Map<String, dynamic>).toList();
});

final analyticsTopServicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(analyticsRemoteProvider);
  final data = await datasource.getTopServices();
  return data.map((e) => e as Map<String, dynamic>).toList();
});

final analyticsPerformanceByDayProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(analyticsRemoteProvider);
  final data = await datasource.getPerformanceByDay();
  return data.map((e) => e as Map<String, dynamic>).toList();
});
