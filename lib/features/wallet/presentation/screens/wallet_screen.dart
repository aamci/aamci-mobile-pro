import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wallet_provider.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletProvider);
    final movementsAsync = ref.watch(walletMovementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Portefeuille')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletProvider);
          ref.invalidate(walletMovementsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            walletAsync.when(
              loading: () => const Card(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Erreur de chargement', style: TextStyle(color: Colors.grey[600])),
                ),
              ),
              data: (wallet) {
                final balance = wallet['balance'] ?? wallet['amount'] ?? 0;
                final currency = wallet['currency'] as String? ?? 'XAF';
                return Card(
                  color: Theme.of(context).colorScheme.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Text('Solde disponible', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          '$balance $currency',
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Mouvements', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            movementsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erreur', style: TextStyle(color: Colors.grey[600])),
              data: (movements) {
                if (movements.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Center(
                      child: Text('Aucun mouvement', style: TextStyle(color: Colors.grey[500])),
                    ),
                  );
                }
                return Column(
                  children: movements.map((m) {
                    final type = m['type'] as String? ?? '';
                    final amount = m['amount'] ?? 0;
                    final date = m['createdAt'] as String? ?? '';
                    final isCredit = type == 'CREDIT' || type == 'PAYMENT';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isCredit ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          child: Icon(
                            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isCredit ? Colors.green : Colors.red,
                            size: 18,
                          ),
                        ),
                        title: Text(_typeLabel(type)),
                        subtitle: Text(date.length >= 10 ? date.substring(0, 10) : date,
                            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        trailing: Text(
                          '${isCredit ? '+' : '-'}$amount',
                          style: TextStyle(
                            color: isCredit ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'CREDIT':
        return 'Crédit';
      case 'DEBIT':
        return 'Débit';
      case 'COMMISSION':
        return 'Commission';
      case 'WITHDRAWAL':
        return 'Retrait';
      case 'PAYMENT':
        return 'Paiement reçu';
      default:
        return type;
    }
  }
}
