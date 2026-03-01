import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/team_provider.dart';

class TeamScreen extends ConsumerStatefulWidget {
  const TeamScreen({super.key});

  @override
  ConsumerState<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends ConsumerState<TeamScreen> {
  @override
  Widget build(BuildContext context) {
    final teamState = ref.watch(teamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon \u00e9quipe'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInviteDialog(context),
        child: const Icon(Icons.person_add),
      ),
      body: _buildBody(teamState),
    );
  }

  Widget _buildBody(TeamState teamState) {
    if (teamState.isLoading && teamState.members.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (teamState.error != null && teamState.members.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              teamState.error!,
              style: TextStyle(color: Colors.red[400]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(teamProvider.notifier).load(),
              child: const Text('R\u00e9essayer'),
            ),
          ],
        ),
      );
    }

    if (teamState.members.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun membre dans votre \u00e9quipe',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Invitez des collaborateurs pour commencer',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(teamProvider.notifier).load(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: teamState.members.length,
        itemBuilder: (context, index) {
          final member = teamState.members[index];
          return _MemberCard(
            member: member,
            onDeactivate: () => _handleDeactivate(member),
            onReactivate: () => _handleReactivate(member),
            onRemove: () => _handleRemove(member),
          );
        },
      ),
    );
  }

  Future<void> _handleDeactivate(Map<String, dynamic> member) async {
    final id = member['id']?.toString() ?? '';
    final success = await ref.read(teamProvider.notifier).deactivate(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Membre d\u00e9sactiv\u00e9'
              : '\u00c9chec de la d\u00e9sactivation'),
        ),
      );
    }
  }

  Future<void> _handleReactivate(Map<String, dynamic> member) async {
    final id = member['id']?.toString() ?? '';
    final success = await ref.read(teamProvider.notifier).reactivate(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Membre r\u00e9activ\u00e9'
              : '\u00c9chec de la r\u00e9activation'),
        ),
      );
    }
  }

  Future<void> _handleRemove(Map<String, dynamic> member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le membre'),
        content: const Text(
            '\u00cates-vous s\u00fbr de vouloir supprimer ce membre de l\'\u00e9quipe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final id = member['id']?.toString() ?? '';
      final success = await ref.read(teamProvider.notifier).remove(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Membre supprim\u00e9'
                : '\u00c9chec de la suppression'),
          ),
        );
      }
    }
  }

  void _showInviteDialog(BuildContext context) {
    final emailController = TextEditingController();
    String selectedRole = 'SECRETARY';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Inviter un membre'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'email@exemple.com',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez saisir un email';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'R\u00f4le',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'SECRETARY',
                      child: Text('Secr\u00e9taire'),
                    ),
                    DropdownMenuItem(
                      value: 'ASSISTANT',
                      child: Text('Assistant(e)'),
                    ),
                    DropdownMenuItem(
                      value: 'NURSE',
                      child: Text('Infirmier(\u00e8re)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedRole = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(dialogContext);
                  final success =
                      await ref.read(teamProvider.notifier).invite(
                            email: emailController.text.trim(),
                            role: selectedRole,
                          );
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Invitation envoy\u00e9e'
                            : '\u00c9chec de l\'invitation'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Inviter'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;
  final VoidCallback onRemove;

  const _MemberCard({
    required this.member,
    required this.onDeactivate,
    required this.onReactivate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final user = member['user'] as Map<String, dynamic>?;
    final name = user?['fullName'] as String? ??
        member['email'] as String? ??
        'Membre';
    final role = member['role'] as String? ?? '';
    final status = member['status'] as String? ?? 'ACTIVE';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(status).withValues(alpha: 0.15),
          child: Text(
            initial,
            style: TextStyle(
              color: _statusColor(status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Text(_roleLabel(role)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusLabel(status),
                style: TextStyle(
                  fontSize: 11,
                  color: _statusColor(status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'deactivate':
                onDeactivate();
                break;
              case 'reactivate':
                onReactivate();
                break;
              case 'remove':
                onRemove();
                break;
            }
          },
          itemBuilder: (context) => [
            if (status == 'ACTIVE')
              const PopupMenuItem(
                value: 'deactivate',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20),
                    SizedBox(width: 8),
                    Text('D\u00e9sactiver'),
                  ],
                ),
              ),
            if (status == 'INACTIVE')
              const PopupMenuItem(
                value: 'reactivate',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text('R\u00e9activer'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'INACTIVE':
        return Colors.grey;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Actif';
      case 'INACTIVE':
        return 'Inactif';
      case 'PENDING':
        return 'En attente';
      default:
        return status;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'SECRETARY':
        return 'Secr\u00e9taire';
      case 'ASSISTANT':
        return 'Assistant(e)';
      case 'NURSE':
        return 'Infirmier(\u00e8re)';
      default:
        return role;
    }
  }
}
