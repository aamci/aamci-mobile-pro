import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/tasks_remote_datasource.dart';

final tasksRemoteProvider = Provider<TasksRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TasksRemoteDatasource(apiClient);
});

// State
class TasksState {
  final List<Map<String, dynamic>> tasks;
  final Map<String, dynamic>? stats;
  final bool isLoading;
  final String? error;

  const TasksState({
    this.tasks = const [],
    this.stats,
    this.isLoading = false,
    this.error,
  });

  TasksState copyWith({
    List<Map<String, dynamic>>? tasks,
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? error,
  }) =>
      TasksState(
        tasks: tasks ?? this.tasks,
        stats: stats ?? this.stats,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class TasksNotifier extends StateNotifier<TasksState> {
  final TasksRemoteDatasource _datasource;

  TasksNotifier(this._datasource) : super(const TasksState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _datasource.getTasks(),
        _datasource.getStats(),
      ]);
      state = state.copyWith(
        tasks: (results[0] as List).whereType<Map<String, dynamic>>().toList(),
        stats: results[1] as Map<String, dynamic>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createTask({
    required String title,
    String? description,
    required String priority,
    required String category,
    required String status,
    String? dueDate,
    String? patientId,
    List<String> tags = const [],
  }) async {
    try {
      await _datasource.createTask(
        title: title,
        description: description,
        priority: priority,
        category: category,
        status: status,
        dueDate: dueDate,
        patientId: patientId,
        tags: tags,
      );
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateStatus(String id, String newStatus) async {
    // Optimistic update
    state = state.copyWith(
      tasks: state.tasks
          .map((t) => t['id'] == id ? {...t, 'status': newStatus} : t)
          .toList(),
    );
    try {
      await _datasource.updateTask(id, {'status': newStatus});
      await load();
      return true;
    } catch (e) {
      await load(); // Revert on error
      return false;
    }
  }

  Future<bool> updateTask(String id, Map<String, dynamic> data) async {
    try {
      await _datasource.updateTask(id, data);
      await load();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    try {
      await _datasource.deleteTask(id);
      state = state.copyWith(
        tasks: state.tasks.where((t) => t['id'] != id).toList(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, TasksState>((ref) {
  final datasource = ref.watch(tasksRemoteProvider);
  return TasksNotifier(datasource);
});
