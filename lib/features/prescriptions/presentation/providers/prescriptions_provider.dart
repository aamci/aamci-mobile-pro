import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/prescriptions_remote_datasource.dart';

final prescriptionsRemoteProvider = Provider<PrescriptionsRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PrescriptionsRemoteDatasource(apiClient);
});

final prescriptionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(prescriptionsRemoteProvider);
  final data = await datasource.getPrescriptions();
  return data.map((e) => e as Map<String, dynamic>).toList();
});

final prescriptionDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final datasource = ref.watch(prescriptionsRemoteProvider);
  return datasource.getPrescription(id);
});
