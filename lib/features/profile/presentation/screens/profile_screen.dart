import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              (user?.fullName ?? 'D').substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Dr. ${user?.fullName ?? 'Médecin'}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          if (user?.specialty != null) ...[
            const SizedBox(height: 4),
            Text(
              user!.specialty!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('Messages'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/messages'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/notifications'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Règles de disponibilité'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/availability-rules'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.event_busy),
                  title: const Text('Absences'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/absences'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.medical_services_outlined),
                  title: const Text('Consultations'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/consultations'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.note_alt_outlined),
                  title: const Text('Notes médicales'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/medical-notes'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Ordonnances'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/prescriptions'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Types de consultation'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/appointment-kinds'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Portefeuille'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/wallet'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('Facturation'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/invoices'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.people_outlined),
                  title: const Text('Mon \u00e9quipe'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/team'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('Analytique'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/analytics'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Changer le mot de passe'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Se déconnecter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
