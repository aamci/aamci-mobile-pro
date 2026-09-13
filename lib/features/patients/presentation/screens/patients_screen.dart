import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../providers/patients_provider.dart';

class _PatientsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class PatientsScreen extends ConsumerWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(patientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
      body: state.isLoading && state.patients.isEmpty
          ? _PatientsSkeleton()
          : state.error != null
              ? AppEmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Erreur de chargement',
                  subtitle: state.error,
                  buttonLabel: 'Réessayer',
                  onButtonPressed: () => ref.read(patientsProvider.notifier).load(),
                )
              : state.patients.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.people_outline_rounded,
                      title: 'Aucun patient',
                      subtitle: 'Vos patients apparaîtront ici après leur première consultation',
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(patientsProvider.notifier).load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.patients.length,
                        itemBuilder: (context, index) {
                          final patient = state.patients[index];
                          final primary = Theme.of(context).colorScheme.primary;
                          final name = patient['fullName'] as String? ?? 'Patient';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: primary.withValues(alpha: 0.1),
                                child: Text(
                                  name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(color: primary, fontWeight: FontWeight.w700),
                                ),
                              ),
                              title: Text(name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                              subtitle: Text(patient['email'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall),
                              trailing: Icon(Icons.chevron_right_rounded, color: primary.withValues(alpha: 0.5)),
                              onTap: () {
                                final id = patient['id']?.toString();
                                if (id != null) context.push('/patient/$id', extra: patient);
                              },
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 300.ms, delay: (index * 50).ms)
                              .slideY(begin: 0.04, curve: Curves.easeOut);
                        },
                      ),
                    ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau patient'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6 ? 'Min. 6 caractères' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Téléphone (optionnel)'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final success = await ref.read(patientsProvider.notifier).createPatient(
                    email: emailCtrl.text.trim(),
                    fullName: nameCtrl.text.trim(),
                    password: passwordCtrl.text,
                    phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Patient créé' : 'Erreur de création')),
                );
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
}
