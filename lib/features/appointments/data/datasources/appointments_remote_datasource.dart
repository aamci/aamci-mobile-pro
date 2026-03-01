import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/appointment_model.dart';

class AppointmentsRemoteDatasource {
  final ApiClient _apiClient;

  AppointmentsRemoteDatasource(this._apiClient);

  Future<List<AppointmentModel>> getAppointments() async {
    final response = await _apiClient.get(ApiEndpoints.appointments);
    final list = response.data as List;
    return list.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> updateStatus(String id, String status) async {
    await _apiClient.patch(
      ApiEndpoints.appointmentStatus(id),
      data: {'status': status},
    );
  }
}
