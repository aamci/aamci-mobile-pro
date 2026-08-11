import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class QuestionnairesRemoteDatasource {
  final ApiClient _apiClient;
  QuestionnairesRemoteDatasource(this._apiClient);

  Future<List<dynamic>> getMine() async {
    final response = await _apiClient.get(ApiEndpoints.questionnairesMine);
    return response.data as List;
  }

  Future<Map<String, dynamic>> create({
    required String title,
    String? description,
  }) async {
    final body = <String, dynamic>{'title': title};
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    final response = await _apiClient.post(ApiEndpoints.createQuestionnaire, data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<void> setActive(String id, bool isActive) async {
    await _apiClient.patch(ApiEndpoints.questionnaireById(id), data: {'isActive': isActive});
  }

  Future<void> delete(String id) async {
    await _apiClient.delete(ApiEndpoints.questionnaireById(id));
  }
}
