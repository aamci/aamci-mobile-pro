import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/waitlist_remote_datasource.dart';

final waitlistRemoteProvider = Provider<WaitlistRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WaitlistRemoteDatasource(apiClient);
});

class WaitlistState {
  final List<Map<String, dynamic>> entries;
  final bool isLoading;
  final String? error;

  const WaitlistState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  WaitlistState copyWith({
    List<Map<String, dynamic>>? entries,
    bool? isLoading,
    String? error,
  }) =>
      WaitlistState(
        entries: entries ?? this.entries,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class WaitlistNotifier extends StateNotifier<WaitlistState> {
  final WaitlistRemoteDatasource _datasource;
  final Ref _ref;

  WaitlistNotifier(this._datasource, this._ref) : super(const WaitlistState());

  Future<void> load() async {
    final doctorId = _ref.read(authProvider).user?.id;
    if (doctorId == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _datasource.getWaitlist(doctorId);
      state = state.copyWith(
        entries: data.whereType<Map<String, dynamic>>().toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> deleteEntry(String id) async {
    try {
      await _datasource.deleteEntry(id);
      state = state.copyWith(
        entries: state.entries.where((e) => e['id'] != id).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

final waitlistProvider = StateNotifierProvider<WaitlistNotifier, WaitlistState>((ref) {
  final datasource = ref.watch(waitlistRemoteProvider);
  return WaitlistNotifier(datasource, ref);
});
