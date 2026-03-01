import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class AbsencesRemoteDatasource {
  final ApiClient _apiClient;

  AbsencesRemoteDatasource(this._apiClient);

  Future<List<dynamic>> getAbsences() async {
    final response = await _apiClient.get(ApiEndpoints.doctorAbsences);
    return response.data as List;
  }

  Future<Map<String, dynamic>> createAbsence({
    required String startDate,
    required String endDate,
    required String type,
    String? reason,
  }) async {
    final response = await _apiClient.post(ApiEndpoints.doctorAbsences, data: {
      'startDate': startDate,
      'endDate': endDate,
      'type': type,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteAbsence(String id) async {
    await _apiClient.delete(ApiEndpoints.doctorAbsenceById(id));
  }
}
