import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class PatientsRemoteDatasource {
  final ApiClient _apiClient;

  PatientsRemoteDatasource(this._apiClient);

  Future<List<dynamic>> getPatients() async {
    final response = await _apiClient.get(ApiEndpoints.patients);
    return response.data as List;
  }

  Future<Map<String, dynamic>> createPatient({
    required String email,
    required String fullName,
    required String password,
    String? phone,
    String? city,
  }) async {
    final response = await _apiClient.post(ApiEndpoints.createPatient, data: {
      'email': email,
      'fullName': fullName,
      'password': password,
      if (phone != null) 'phone': phone,
      if (city != null) 'city': city,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPatientRecord(String patientId) async {
    final response = await _apiClient.get(ApiEndpoints.patientRecord(patientId));
    return response.data as Map<String, dynamic>;
  }
}
