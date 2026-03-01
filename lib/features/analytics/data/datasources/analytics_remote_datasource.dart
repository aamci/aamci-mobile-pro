import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class AnalyticsRemoteDatasource {
  final ApiClient _apiClient;
  AnalyticsRemoteDatasource(this._apiClient);

  Future<Map<String, dynamic>> getDashboard({String period = '30d'}) async {
    final response = await _apiClient.get('${ApiEndpoints.analyticsDashboard}?period=$period');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getTrends() async {
    final response = await _apiClient.get(ApiEndpoints.analyticsTrends);
    return response.data as List;
  }

  Future<List<dynamic>> getTopServices() async {
    final response = await _apiClient.get(ApiEndpoints.analyticsTopServices);
    return response.data as List;
  }

  Future<List<dynamic>> getPerformanceByDay() async {
    final response = await _apiClient.get(ApiEndpoints.analyticsPerformanceByDay);
    return response.data as List;
  }
}
