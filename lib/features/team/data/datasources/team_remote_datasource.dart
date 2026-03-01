import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class TeamRemoteDatasource {
  final ApiClient _apiClient;
  TeamRemoteDatasource(this._apiClient);

  Future<List<dynamic>> getTeamMembers() async {
    final response = await _apiClient.get(ApiEndpoints.team);
    return response.data as List;
  }

  Future<Map<String, dynamic>> getTeamStats() async {
    final response = await _apiClient.get(ApiEndpoints.teamStats);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> inviteMember({
    required String email,
    required String role,
    List<String>? permissions,
  }) async {
    final response = await _apiClient.post(ApiEndpoints.teamInvite, data: {
      'email': email,
      'role': role,
      if (permissions != null) 'permissions': permissions,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<void> deactivateMember(String id) async {
    await _apiClient.post(ApiEndpoints.teamDeactivate(id));
  }

  Future<void> reactivateMember(String id) async {
    await _apiClient.post(ApiEndpoints.teamReactivate(id));
  }

  Future<void> removeMember(String id) async {
    await _apiClient.delete(ApiEndpoints.teamMemberById(id));
  }
}
