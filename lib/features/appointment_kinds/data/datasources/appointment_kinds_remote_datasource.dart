import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class AppointmentKindsRemoteDatasource {
  final ApiClient _apiClient;

  AppointmentKindsRemoteDatasource(this._apiClient);

  Future<List<dynamic>> getMyKinds() async {
    final response = await _apiClient.get(ApiEndpoints.appointmentKinds);
    return response.data as List;
  }

  Future<Map<String, dynamic>> createKind({
    required String name,
    required int durationMins,
    double? price,
    String? color,
  }) async {
    final response = await _apiClient.post(ApiEndpoints.appointmentKinds, data: {
      'name': name,
      'durationMins': durationMins,
      if (price != null) 'price': price,
      if (color != null) 'color': color,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateKind(String id, {
    String? name,
    int? durationMins,
    double? price,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (durationMins != null) data['durationMins'] = durationMins;
    if (price != null) data['price'] = price;
    final response = await _apiClient.patch(ApiEndpoints.appointmentKindById(id), data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteKind(String id) async {
    await _apiClient.delete(ApiEndpoints.appointmentKindById(id));
  }
}
