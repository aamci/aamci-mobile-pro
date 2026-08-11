import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/referrals_remote_datasource.dart';

final referralsRemoteProvider = Provider<ReferralsRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReferralsRemoteDatasource(apiClient);
});

class ReferralsState {
  final List<Map<String, dynamic>> sent;
  final List<Map<String, dynamic>> received;
  final List<Map<String, dynamic>> receivedPatients;
  final bool isLoading;
  final String? error;

  const ReferralsState({
    this.sent = const [],
    this.received = const [],
    this.receivedPatients = const [],
    this.isLoading = false,
    this.error,
  });

  ReferralsState copyWith({
    List<Map<String, dynamic>>? sent,
    List<Map<String, dynamic>>? received,
    List<Map<String, dynamic>>? receivedPatients,
    bool? isLoading,
    String? error,
  }) =>
      ReferralsState(
        sent: sent ?? this.sent,
        received: received ?? this.received,
        receivedPatients: receivedPatients ?? this.receivedPatients,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class ReferralsNotifier extends StateNotifier<ReferralsState> {
  final ReferralsRemoteDatasource _datasource;

  ReferralsNotifier(this._datasource) : super(const ReferralsState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _datasource.getSent(),
        _datasource.getReceived(),
        _datasource.getReceivedPatients(),
      ]);
      state = state.copyWith(
        sent: (results[0]).whereType<Map<String, dynamic>>().toList(),
        received: (results[1]).whereType<Map<String, dynamic>>().toList(),
        receivedPatients: (results[2]).whereType<Map<String, dynamic>>().toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> create({
    required String patientId,
    required String toDoctorId,
    required String reason,
    String urgency = 'NORMAL',
    String? notes,
  }) async {
    try {
      await _datasource.create(
        patientId: patientId,
        toDoctorId: toDoctorId,
        reason: reason,
        urgency: urgency,
        notes: notes,
      );
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> respond(String id, {required bool accept, String? response}) async {
    try {
      await _datasource.respond(id, accept: accept, response: response);
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> complete(String id) async {
    try {
      await _datasource.complete(id);
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final referralsProvider = StateNotifierProvider<ReferralsNotifier, ReferralsState>((ref) {
  final datasource = ref.watch(referralsRemoteProvider);
  return ReferralsNotifier(datasource);
});
