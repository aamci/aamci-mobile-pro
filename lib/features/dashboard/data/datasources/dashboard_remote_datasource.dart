import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/stats_model.dart';

class DashboardRemoteDatasource {
  final ApiClient _apiClient;

  DashboardRemoteDatasource(this._apiClient);

  Future<DoctorStats> getOverview() async {
    final response = await _apiClient.get(ApiEndpoints.doctorOverview);
    return DoctorStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<NextAppointment>> getNextAppointments({int limit = 5}) async {
    final response = await _apiClient.get(
      ApiEndpoints.nextAppointments,
      queryParameters: {'limit': limit},
    );
    final list = response.data as List;
    return list.map((e) => NextAppointment.fromJson(e as Map<String, dynamic>)).toList();
  }
}
