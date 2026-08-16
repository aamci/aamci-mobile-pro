import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class ConsultationsRemoteDatasource {
  final ApiClient _apiClient;

  ConsultationsRemoteDatasource(this._apiClient);

  Future<List<dynamic>> getConsultations() async {
    final response = await _apiClient.get('${ApiEndpoints.consultations}/mine');
    return response.data as List;
  }

  Future<Map<String, dynamic>> getConsultation(String id) async {
    final response = await _apiClient.get(ApiEndpoints.consultationById(id));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createConsultation({
    required String appointmentId,
    String? notes,
    String? diagnosis,
  }) async {
    final response = await _apiClient.post(ApiEndpoints.consultations, data: {
      'appointmentId': appointmentId,
      if (notes != null) 'notes': notes,
      if (diagnosis != null) 'diagnosis': diagnosis,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateConsultation(String id, {
    String? notes,
    String? diagnosis,
  }) async {
    final data = <String, dynamic>{};
    if (notes != null) data['notes'] = notes;
    if (diagnosis != null) data['diagnosis'] = diagnosis;
    final response = await _apiClient.patch(ApiEndpoints.consultationById(id), data: data);
    return response.data as Map<String, dynamic>;
  }
}
