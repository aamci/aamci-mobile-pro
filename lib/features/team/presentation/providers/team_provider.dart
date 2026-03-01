import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/team_remote_datasource.dart';

final teamRemoteProvider = Provider<TeamRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TeamRemoteDatasource(apiClient);
});

class TeamState {
  final List<Map<String, dynamic>> members;
  final bool isLoading;
  final String? error;

  const TeamState({
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  TeamState copyWith({
    List<Map<String, dynamic>>? members,
    bool? isLoading,
    String? error,
  }) {
    return TeamState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class TeamNotifier extends StateNotifier<TeamState> {
  final TeamRemoteDatasource _datasource;

  TeamNotifier(this._datasource) : super(const TeamState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _datasource.getTeamMembers();
      final members = data.map((e) => e as Map<String, dynamic>).toList();
      state = state.copyWith(members: members, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erreur de chargement');
    }
  }

  Future<bool> invite({
    required String email,
    required String role,
    List<String>? permissions,
  }) async {
    try {
      await _datasource.inviteMember(
        email: email,
        role: role,
        permissions: permissions,
      );
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deactivate(String id) async {
    try {
      await _datasource.deactivateMember(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> reactivate(String id) async {
    try {
      await _datasource.reactivateMember(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(String id) async {
    try {
      await _datasource.removeMember(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final teamProvider = StateNotifierProvider<TeamNotifier, TeamState>((ref) {
  final datasource = ref.watch(teamRemoteProvider);
  return TeamNotifier(datasource);
});
