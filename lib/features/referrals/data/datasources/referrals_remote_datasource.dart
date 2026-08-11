import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class ReferralsRemoteDatasource {
  final ApiClient _apiClient;
  ReferralsRemoteDatasource(this._apiClient);

  Future<List<dynamic>> getSent() async {
    final response = await _apiClient.get(ApiEndpoints.referralsSent);
    return response.data as List;
  }

  Future<List<dynamic>> getReceived() async {
    final response = await _apiClient.get(ApiEndpoints.referralsReceived);
    return response.data as List;
  }

  Future<List<dynamic>> getReceivedPatients() async {
    final response = await _apiClient.get(ApiEndpoints.referralsReceivedPatients);
    return response.data as List;
  }

  Future<Map<String, dynamic>> create({
    required String patientId,
    required String toDoctorId,
    required String reason,
    String urgency = 'NORMAL',
    String? notes,
  }) async {
    final response = await _apiClient.post(ApiEndpoints.referrals, data: {
      'patientId': patientId,
      'toDoctorId': toDoctorId,
      'reason': reason,
      'urgency': urgency,
      if (notes != null) 'notes': notes,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> respond(String id, {required bool accept, String? response}) async {
    final res = await _apiClient.patch(ApiEndpoints.referralRespond(id), data: {
      'status': accept ? 'ACCEPTED' : 'REJECTED',
      if (response != null) 'response': response,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> complete(String id) async {
    final response = await _apiClient.patch(ApiEndpoints.referralComplete(id), data: {});
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> searchDoctors(String query) async {
    final response = await _apiClient.get('${ApiEndpoints.doctorSearch}?q=${Uri.encodeComponent(query)}');
    return response.data as List;
  }
}
