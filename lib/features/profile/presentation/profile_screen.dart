import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common.dart';
import '../../designs/presentation/design_providers.dart';
import '../../favorites/presentation/favorites_providers.dart';
import 'auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final looks = ref.watch(favoritesProvider).value?.length ?? 0;
    final designs = ref.watch(designsProvider).value?.length ?? 0;
    final name = user?.displayName ?? 'Guest';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.lavender,
                  child: Text(name.characters.first.toUpperCase(),
                      style: const TextStyle(color: AppColors.white, fontSize: 26, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(user == null || user.isGuest ? 'Guest account' : (user.email ?? ''),
                          style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit name',
                  icon: const Icon(Icons.edit_outlined, color: AppColors.deepPurple),
                  onPressed: () => _editName(context, ref, name),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _StatCard('$looks', 'Saved looks', Icons.favorite_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _StatCard('$designs', 'Designs', Icons.checkroom_rounded)),
            ],
          ),
          const SizedBox(height: 16),
          if (user == null || user.isGuest)
            AppCard(
              color: AppColors.lavenderSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Create your account', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  const Text('Keep your looks safe and use them on any device.',
                      style: TextStyle(color: AppColors.muted, fontSize: 13)),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: AppColors.cream,
                      builder: (_) => const _AuthSheet(),
                    ),
                    child: const Text('Sign up / Sign in'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_outlined, color: AppColors.deepPurple),
                  title: const Text('Data storage'),
                  subtitle: Text(AppConfig.useFirebase ? 'Firebase cloud' : 'On this device'),
                ),
                ListTile(
                  leading: const Icon(Icons.replay_rounded, color: AppColors.deepPurple),
                  title: const Text('Replay introduction'),
                  onTap: () async {
                    await ref.read(sharedPreferencesProvider).setBool(onboardingSeenKey, false);
                    if (context.mounted) context.go(AppRoutes.onboarding);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.deepPurple),
                  title: const Text('About Fabric2Fit'),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: AppConfig.appName,
                    applicationVersion: '1.0.0',
                    applicationLegalese: AppConfig.tagline,
                  ),
                ),
                if (user != null && !user.isGuest)
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppColors.rose),
                    title: const Text('Sign out'),
                    onTap: () => ref.read(authRepositoryProvider).signOut(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(c, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      final auth = ref.read(authRepositoryProvider);
      if (auth.currentUser == null) await auth.continueAsGuest();
      await auth.updateDisplayName(name);
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.value, this.label, this.icon);
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Row(
          children: [
            Icon(icon, color: AppColors.rose),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleLarge),
                Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ],
        ),
      );
}

class _AuthSheet extends ConsumerStatefulWidget {
  const _AuthSheet();

  @override
  ConsumerState<_AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends ConsumerState<_AuthSheet> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _signUp = true;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (!email.contains('@') || _password.text.length < 6 || (_signUp && _name.text.trim().isEmpty)) {
      setState(() => _error = 'Enter your name, a valid email and a password of 6+ characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final auth = ref.read(authRepositoryProvider);
      if (_signUp) {
        await auth.signUpWithEmail(_name.text.trim(), email, _password.text);
      } else {
        await auth.signInWithEmail(email, _password.text);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_signUp ? 'Create account' : 'Welcome back', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 18),
            if (_signUp) ...[
              TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Please wait…' : (_signUp ? 'Sign up' : 'Sign in')),
            ),
            TextButton(
              onPressed: () => setState(() => _signUp = !_signUp),
              child: Text(_signUp ? 'Already have an account? Sign in' : 'New here? Create an account'),
            ),
          ],
        ),
      );
}
