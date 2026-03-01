import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/availability_rules_remote_datasource.dart';

final availabilityRulesRemoteProvider = Provider<AvailabilityRulesRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AvailabilityRulesRemoteDatasource(apiClient);
});

class AvailabilityRulesState {
  final List<Map<String, dynamic>> rules;
  final bool isLoading;
  final String? error;

  const AvailabilityRulesState({
    this.rules = const [],
    this.isLoading = false,
    this.error,
  });

  AvailabilityRulesState copyWith({
    List<Map<String, dynamic>>? rules,
    bool? isLoading,
    String? error,
  }) {
    return AvailabilityRulesState(
      rules: rules ?? this.rules,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AvailabilityRulesNotifier extends StateNotifier<AvailabilityRulesState> {
  final AvailabilityRulesRemoteDatasource _datasource;

  AvailabilityRulesNotifier(this._datasource) : super(const AvailabilityRulesState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _datasource.getMyRules();
      final rules = data.map((e) => e as Map<String, dynamic>).toList();
      state = state.copyWith(rules: rules, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur de chargement');
    }
  }

  Future<bool> create({
    required List<int> daysOfWeek,
    required String startHour,
    required String endHour,
    required int slotDurationMins,
  }) async {
    try {
      await _datasource.createRule(
        daysOfWeek: daysOfWeek,
        startHour: startHour,
        endHour: endHour,
        slotDurationMins: slotDurationMins,
      );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> update(String id, {
    List<int>? daysOfWeek,
    String? startHour,
    String? endHour,
    int? slotDurationMins,
  }) async {
    try {
      await _datasource.updateRule(id,
        daysOfWeek: daysOfWeek,
        startHour: startHour,
        endHour: endHour,
        slotDurationMins: slotDurationMins,
      );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _datasource.deleteRule(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final availabilityRulesProvider =
    StateNotifierProvider<AvailabilityRulesNotifier, AvailabilityRulesState>((ref) {
  final datasource = ref.watch(availabilityRulesRemoteProvider);
  return AvailabilityRulesNotifier(datasource);
});
