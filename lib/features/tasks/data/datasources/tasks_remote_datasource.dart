import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class TasksRemoteDatasource {
  final ApiClient _apiClient;
  TasksRemoteDatasource(this._apiClient);

  Future<List<dynamic>> getTasks() async {
    final response = await _apiClient.get(ApiEndpoints.tasks);
    return response.data as List;
  }

  Future<Map<String, dynamic>> getStats() async {
    final response = await _apiClient.get(ApiEndpoints.taskStats);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTask({
    required String title,
    String? description,
    required String priority,
    required String category,
    required String status,
    String? dueDate,
    String? patientId,
    List<String> tags = const [],
  }) async {
    final response = await _apiClient.post(ApiEndpoints.tasks, data: {
      'title': title,
      if (description != null) 'description': description,
      'priority': priority,
      'category': category,
      'status': status,
      if (dueDate != null) 'dueDate': dueDate,
      if (patientId != null) 'patientId': patientId,
      'tags': tags,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTask(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch(ApiEndpoints.taskById(id), data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteTask(String id) async {
    await _apiClient.delete(ApiEndpoints.taskById(id));
  }
}
