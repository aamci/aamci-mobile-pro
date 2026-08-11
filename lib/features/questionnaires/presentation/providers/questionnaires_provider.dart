import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/questionnaires_remote_datasource.dart';

final questionnairesRemoteProvider = Provider<QuestionnairesRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return QuestionnairesRemoteDatasource(apiClient);
});

class QuestionnairesState {
  final List<Map<String, dynamic>> questionnaires;
  final bool isLoading;
  final String? error;

  const QuestionnairesState({
    this.questionnaires = const [],
    this.isLoading = false,
    this.error,
  });

  QuestionnairesState copyWith({
    List<Map<String, dynamic>>? questionnaires,
    bool? isLoading,
    String? error,
  }) =>
      QuestionnairesState(
        questionnaires: questionnaires ?? this.questionnaires,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class QuestionnairesNotifier extends StateNotifier<QuestionnairesState> {
  final QuestionnairesRemoteDatasource _datasource;

  QuestionnairesNotifier(this._datasource) : super(const QuestionnairesState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _datasource.getMine();
      state = state.copyWith(
        questionnaires: data.whereType<Map<String, dynamic>>().toList(),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> create({required String title, String? description}) async {
    try {
      await _datasource.create(title: title, description: description);
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setActive(String id, bool isActive) async {
    // Optimistic update
    state = state.copyWith(
      questionnaires: state.questionnaires
          .map((q) => q['id'] == id ? {...q, 'isActive': isActive} : q)
          .toList(),
    );
    try {
      await _datasource.setActive(id, isActive);
      return true;
    } catch (e) {
      await load(); // Revert on error
      return false;
    }
  }

  Future<bool> delete(String id) async {
    try {
      await _datasource.delete(id);
      state = state.copyWith(
        questionnaires: state.questionnaires.where((q) => q['id'] != id).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

final questionnairesProvider =
    StateNotifierProvider<QuestionnairesNotifier, QuestionnairesState>((ref) {
  final datasource = ref.watch(questionnairesRemoteProvider);
  return QuestionnairesNotifier(datasource);
});
