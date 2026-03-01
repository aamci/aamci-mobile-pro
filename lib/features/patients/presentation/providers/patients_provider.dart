import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/patients_remote_datasource.dart';

final patientsRemoteProvider = Provider<PatientsRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PatientsRemoteDatasource(apiClient);
});

class PatientsState {
  final List<Map<String, dynamic>> patients;
  final bool isLoading;
  final String? error;

  const PatientsState({
    this.patients = const [],
    this.isLoading = false,
    this.error,
  });

  PatientsState copyWith({
    List<Map<String, dynamic>>? patients,
    bool? isLoading,
    String? error,
  }) {
    return PatientsState(
      patients: patients ?? this.patients,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PatientsNotifier extends StateNotifier<PatientsState> {
  final PatientsRemoteDatasource _datasource;

  PatientsNotifier(this._datasource) : super(const PatientsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _datasource.getPatients();
      final patients = data.map((e) => e as Map<String, dynamic>).toList();
      state = state.copyWith(patients: patients, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur de chargement');
    }
  }

  Future<bool> createPatient({
    required String email,
    required String fullName,
    required String password,
    String? phone,
    String? city,
  }) async {
    try {
      await _datasource.createPatient(
        email: email,
        fullName: fullName,
        password: password,
        phone: phone,
        city: city,
      );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final patientsProvider = StateNotifierProvider<PatientsNotifier, PatientsState>((ref) {
  final datasource = ref.watch(patientsRemoteProvider);
  return PatientsNotifier(datasource);
});

final patientRecordProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, patientId) async {
  final datasource = ref.watch(patientsRemoteProvider);
  return datasource.getPatientRecord(patientId);
});
