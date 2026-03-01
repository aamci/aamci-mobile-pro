import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/invoices_provider.dart';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Facturation')),
      body: invoicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erreur de chargement', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(invoicesProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (invoices) {
          if (invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Aucune facture', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(invoicesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final inv = invoices[index];
                final patient = inv['patient'] as Map<String, dynamic>? ?? {};
                final patientName = patient['fullName'] as String? ?? 'Patient';
                final amount = inv['amount'] ?? 0;
                final status = inv['status'] as String? ?? 'PENDING';
                final date = inv['createdAt'] as String? ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary),
                    title: Text(patientName),
                    subtitle: Text(date.length >= 10 ? date.substring(0, 10) : date,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$amount', style: const TextStyle(fontWeight: FontWeight.w600)),
                        _statusBadge(status),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'PAID':
        color = Colors.green;
        label = 'Payée';
      case 'PENDING':
        color = Colors.orange;
        label = 'En attente';
      case 'CANCELLED':
        color = Colors.red;
        label = 'Annulée';
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }
}
