import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class ProfileRemoteDatasource {
  final ApiClient _apiClient;

  ProfileRemoteDatasource(this._apiClient);

  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
    String? city,
    String? specialty,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['fullName'] = fullName;
    if (phone != null) data['phone'] = phone;
    if (city != null) data['city'] = city;
    if (specialty != null) data['specialty'] = specialty;

    final response = await _apiClient.put(ApiEndpoints.profile, data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.put(ApiEndpoints.changePassword, data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }
}
