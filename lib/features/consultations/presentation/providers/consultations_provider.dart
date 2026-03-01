import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/consultations_remote_datasource.dart';

final consultationsRemoteProvider = Provider<ConsultationsRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ConsultationsRemoteDatasource(apiClient);
});

final consultationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(consultationsRemoteProvider);
  final data = await datasource.getConsultations();
  return data.whereType<Map<String, dynamic>>().toList();
});

final consultationDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final datasource = ref.watch(consultationsRemoteProvider);
  return datasource.getConsultation(id);
});
