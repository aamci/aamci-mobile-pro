import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/models/stats_model.dart';

final dashboardRemoteProvider = Provider<DashboardRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardRemoteDatasource(apiClient);
});

class DashboardState {
  final DoctorStats? stats;
  final List<NextAppointment> nextAppointments;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.stats,
    this.nextAppointments = const [],
    this.isLoading = false,
    this.error,
  });
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRemoteDatasource _datasource;

  DashboardNotifier(this._datasource) : super(const DashboardState());

  Future<void> load() async {
    state = DashboardState(
      isLoading: true,
      stats: state.stats,
      nextAppointments: state.nextAppointments,
    );
    try {
      final results = await Future.wait([
        _datasource.getOverview(),
        _datasource.getNextAppointments(),
      ]);
      state = DashboardState(
        stats: results[0] as DoctorStats,
        nextAppointments: results[1] as List<NextAppointment>,
      );
    } catch (e) {
      state = DashboardState(
        stats: state.stats,
        nextAppointments: state.nextAppointments,
        error: 'Erreur lors du chargement',
      );
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final datasource = ref.watch(dashboardRemoteProvider);
  return DashboardNotifier(datasource);
});
