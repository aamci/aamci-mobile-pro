import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class AvailabilityRulesRemoteDatasource {
  final ApiClient _apiClient;

  AvailabilityRulesRemoteDatasource(this._apiClient);

  Future<List<dynamic>> getMyRules() async {
    final response = await _apiClient.get(ApiEndpoints.myAvailabilityRules);
    return response.data as List;
  }

  Future<Map<String, dynamic>> createRule({
    required List<int> daysOfWeek,
    required String startHour,
    required String endHour,
    required int slotDurationMins,
  }) async {
    final response = await _apiClient.post(ApiEndpoints.availabilityRules, data: {
      'daysOfWeek': daysOfWeek,
      'startHour': startHour,
      'endHour': endHour,
      'slotDurationMins': slotDurationMins,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateRule(String id, {
    List<int>? daysOfWeek,
    String? startHour,
    String? endHour,
    int? slotDurationMins,
  }) async {
    final data = <String, dynamic>{};
    if (daysOfWeek != null) data['daysOfWeek'] = daysOfWeek;
    if (startHour != null) data['startHour'] = startHour;
    if (endHour != null) data['endHour'] = endHour;
    if (slotDurationMins != null) data['slotDurationMins'] = slotDurationMins;

    final response = await _apiClient.patch(ApiEndpoints.availabilityRuleById(id), data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteRule(String id) async {
    await _apiClient.delete(ApiEndpoints.availabilityRuleById(id));
  }
}
