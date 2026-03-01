import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/availability_rule_model.dart';

class PlanningRemoteDatasource {
  final ApiClient _apiClient;

  PlanningRemoteDatasource(this._apiClient);

  Future<List<AvailabilityRuleModel>> getMyRules() async {
    final response = await _apiClient.get(ApiEndpoints.myAvailabilityRules);
    final list = response.data as List;
    return list
        .map((e) => AvailabilityRuleModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
