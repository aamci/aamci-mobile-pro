import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/absences_remote_datasource.dart';

final absencesRemoteProvider = Provider<AbsencesRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AbsencesRemoteDatasource(apiClient);
});

class AbsencesState {
  final List<Map<String, dynamic>> absences;
  final bool isLoading;
  final String? error;

  const AbsencesState({
    this.absences = const [],
    this.isLoading = false,
    this.error,
  });

  AbsencesState copyWith({
    List<Map<String, dynamic>>? absences,
    bool? isLoading,
    String? error,
  }) {
    return AbsencesState(
      absences: absences ?? this.absences,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AbsencesNotifier extends StateNotifier<AbsencesState> {
  final AbsencesRemoteDatasource _datasource;

  AbsencesNotifier(this._datasource) : super(const AbsencesState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _datasource.getAbsences();
      final absences = data.map((e) => e as Map<String, dynamic>).toList();
      state = state.copyWith(absences: absences, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur de chargement');
    }
  }

  Future<bool> create({
    required String startDate,
    required String endDate,
    required String type,
    String? reason,
  }) async {
    try {
      await _datasource.createAbsence(
        startDate: startDate,
        endDate: endDate,
        type: type,
        reason: reason,
      );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _datasource.deleteAbsence(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final absencesProvider = StateNotifierProvider<AbsencesNotifier, AbsencesState>((ref) {
  final datasource = ref.watch(absencesRemoteProvider);
  return AbsencesNotifier(datasource);
});
