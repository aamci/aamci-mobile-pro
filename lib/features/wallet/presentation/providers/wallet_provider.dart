import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/wallet_remote_datasource.dart';

final walletRemoteProvider = Provider<WalletRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WalletRemoteDatasource(apiClient);
});

final walletProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final datasource = ref.watch(walletRemoteProvider);
  return datasource.getWallet();
});

final walletMovementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(walletRemoteProvider);
  final data = await datasource.getMovements();
  return data.map((e) => e as Map<String, dynamic>).toList();
});
