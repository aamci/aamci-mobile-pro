import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/invoices_remote_datasource.dart';

final invoicesRemoteProvider = Provider<InvoicesRemoteDatasource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InvoicesRemoteDatasource(apiClient);
});

final invoicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final datasource = ref.watch(invoicesRemoteProvider);
  final data = await datasource.getInvoices();
  return data.map((e) => e as Map<String, dynamic>).toList();
});

final invoiceDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final datasource = ref.watch(invoicesRemoteProvider);
  return datasource.getInvoice(id);
});
