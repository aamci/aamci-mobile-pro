import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/medical_notes_remote_datasource.dart';

final medicalNotesRemoteProvider = Provider<MedicalNotesRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MedicalNotesRemoteDatasource(apiClient);
});

final medicalNotesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(medicalNotesRemoteProvider);
  final data = await datasource.getNotes();
  return data.map((e) => e as Map<String, dynamic>).toList();
});
