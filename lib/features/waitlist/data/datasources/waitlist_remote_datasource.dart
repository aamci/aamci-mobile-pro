import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class WaitlistRemoteDatasource {
  final ApiClient _apiClient;
  WaitlistRemoteDatasource(this._apiClient);

  Future<List<dynamic>> getWaitlist(String doctorId) async {
    final response = await _apiClient.get(ApiEndpoints.waitlistDoctor(doctorId));
    return response.data as List;
  }

  Future<void> deleteEntry(String id) async {
    await _apiClient.delete(ApiEndpoints.waitlistEntry(id));
  }
}
