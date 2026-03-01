import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';

class WalletRemoteDatasource {
  final ApiClient _apiClient;

  WalletRemoteDatasource(this._apiClient);

  Future<Map<String, dynamic>> getWallet() async {
    final response = await _apiClient.get(ApiEndpoints.wallet);
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMovements() async {
    final response = await _apiClient.get(ApiEndpoints.walletMovements);
    return response.data as List;
  }
}
