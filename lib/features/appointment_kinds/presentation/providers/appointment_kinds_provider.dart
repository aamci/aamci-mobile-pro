import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/appointment_kinds_remote_datasource.dart';

final appointmentKindsRemoteProvider = Provider<AppointmentKindsRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AppointmentKindsRemoteDatasource(apiClient);
});

class AppointmentKindsState {
  final List<Map<String, dynamic>> kinds;
  final bool isLoading;
  final String? error;

  const AppointmentKindsState({this.kinds = const [], this.isLoading = false, this.error});

  AppointmentKindsState copyWith({List<Map<String, dynamic>>? kinds, bool? isLoading, String? error}) {
    return AppointmentKindsState(
      kinds: kinds ?? this.kinds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AppointmentKindsNotifier extends StateNotifier<AppointmentKindsState> {
  final AppointmentKindsRemoteDatasource _datasource;

  AppointmentKindsNotifier(this._datasource) : super(const AppointmentKindsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _datasource.getMyKinds();
      final kinds = data.map((e) => e as Map<String, dynamic>).toList();
      state = state.copyWith(kinds: kinds, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur de chargement');
    }
  }

  Future<bool> create({required String name, required int durationMins, double? price}) async {
    try {
      await _datasource.createKind(name: name, durationMins: durationMins, price: price);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(String id, {String? name, int? durationMins, double? price}) async {
    try {
      await _datasource.updateKind(id, name: name, durationMins: durationMins, price: price);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _datasource.deleteKind(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final appointmentKindsProvider =
    StateNotifierProvider<AppointmentKindsNotifier, AppointmentKindsState>((ref) {
  final datasource = ref.watch(appointmentKindsRemoteProvider);
  return AppointmentKindsNotifier(datasource);
});
