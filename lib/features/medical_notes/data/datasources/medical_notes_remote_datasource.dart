import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class MedicalNotesRemoteDatasource {
  final ApiClient _apiClient;

  MedicalNotesRemoteDatasource(this._apiClient);

  Future<List<dynamic>> getNotes() async {
    final response = await _apiClient.get(ApiEndpoints.medicalNotes);
    return response.data as List;
  }

  Future<Map<String, dynamic>> createNote({
    required String patientId,
    required String title,
    required String content,
    String? consultationId,
  }) async {
    final response = await _apiClient.post(ApiEndpoints.medicalNotes, data: {
      'patientId': patientId,
      'title': title,
      'content': content,
      if (consultationId != null) 'consultationId': consultationId,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateNote(String id, {String? title, String? content}) async {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (content != null) data['content'] = content;
    final response = await _apiClient.patch(ApiEndpoints.medicalNoteById(id), data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteNote(String id) async {
    await _apiClient.delete(ApiEndpoints.medicalNoteById(id));
  }
}
