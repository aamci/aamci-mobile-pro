import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class PrescriptionsRemoteDatasource {
  final ApiClient _apiClient;

  PrescriptionsRemoteDatasource(this._apiClient);

  Future<List<dynamic>> getPrescriptions() async {
    final response = await _apiClient.get(ApiEndpoints.prescriptions);
    return response.data as List;
  }

  Future<Map<String, dynamic>> getPrescription(String id) async {
    final response = await _apiClient.get(ApiEndpoints.prescriptionById(id));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createPrescription({
    required String patientId,
    required String consultationId,
    required List<Map<String, dynamic>> medications,
    String? notes,
  }) async {
    final response = await _apiClient.post(ApiEndpoints.prescriptions, data: {
      'patientId': patientId,
      'consultationId': consultationId,
      'medications': medications,
      if (notes != null) 'notes': notes,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> deletePrescription(String id) async {
    await _apiClient.delete(ApiEndpoints.prescriptionById(id));
  }

  Future<List<dynamic>> getTemplates() async {
    final response = await _apiClient.get(ApiEndpoints.prescriptionTemplates);
    return response.data as List;
  }
}
