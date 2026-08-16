import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class AvailabilityRulesRemoteDatasource {
  final ApiClient _apiClient;

  AvailabilityRulesRemoteDatasource(this._apiClient);

  Future<List<dynamic>> getMyRules() async {
    final response = await _apiClient.get(ApiEndpoints.myAvailabilityRules);
    return response.data as List;
  }

  static int _parseHour(String h) {
    final parts = h.split(':');
    return int.parse(parts[0]);
  }

  Future<Map<String, dynamic>> createRule({
    required List<int> daysOfWeek,
    required String startHour,
    required String endHour,
    required int slotDurationMins,
  }) async {
    final now = DateTime.now();
    final twoYearsLater = DateTime(now.year + 2, now.month, now.day);
    final response = await _apiClient.post(ApiEndpoints.availabilityRules, data: {
      'daysOfWeek': daysOfWeek,
      'startHour': _parseHour(startHour),
      'endHour': _parseHour(endHour),
      'slotDurationMins': slotDurationMins,
      'capacity': 1,
      'startDate': now.toIso8601String(),
      'endDate': twoYearsLater.toIso8601String(),
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
    if (startHour != null) data['startHour'] = _parseHour(startHour);
    if (endHour != null) data['endHour'] = _parseHour(endHour);
    if (slotDurationMins != null) data['slotDurationMins'] = slotDurationMins;

    final response = await _apiClient.put(ApiEndpoints.availabilityRuleById(id), data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteRule(String id) async {
    await _apiClient.delete(ApiEndpoints.availabilityRuleById(id));
  }
}
