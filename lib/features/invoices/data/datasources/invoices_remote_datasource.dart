import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class InvoicesRemoteDatasource {
  final ApiClient _apiClient;

  InvoicesRemoteDatasource(this._apiClient);

  Future<List<dynamic>> getInvoices() async {
    final response = await _apiClient.get(ApiEndpoints.invoices);
    return response.data as List;
  }

  Future<Map<String, dynamic>> getInvoice(String id) async {
    final response = await _apiClient.get(ApiEndpoints.invoiceById(id));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createInvoice({
    required String patientId,
    required String appointmentId,
    required double amount,
    String? description,
  }) async {
    final response = await _apiClient.post(ApiEndpoints.invoices, data: {
      'patientId': patientId,
      'appointmentId': appointmentId,
      'amount': amount,
      if (description != null) 'description': description,
    });
    return response.data as Map<String, dynamic>;
  }
}
