import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'preferred_name_screen.dart';
import 'reset_password_screen.dart';
import 'services/settings_service.dart';
import 'weekly_budget_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final settingsService = SettingsService();

  Stream<int?>? budgetStream;
  Stream<String?>? nameStream;

  bool isOpeningBudget = false;
  bool isOpeningName = false;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  void loadSettings() {
    try {
      budgetStream = settingsService.watchWeeklyBudgetPence();
      nameStream = settingsService.watchPreferredName();
    } on StateError {
      budgetStream = null;
      nameStream = null;
    }
  }

  void retrySettings() {
    setState(loadSettings);
  }

  String money(int pence) {
    return '£${(pence / 100).toStringAsFixed(2)}';
  }

  Future<void> openName(String? currentName) async {
    if (isOpeningName) return;

    setState(() {
      isOpeningName = true;
    });

    try {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PreferredNameScreen(
            currentName: currentName,
          ),
        ),
      );

      if (!mounted || saved != true) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferred name saved.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isOpeningName = false;
        });
      }
    }
  }

  Future<void> openBudget(int? currentBudgetPence) async {
    if (isOpeningBudget) return;

    setState(() {
      isOpeningBudget = true;
    });

    try {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => WeeklyBudgetScreen(
            currentBudgetPence: currentBudgetPence,
          ),
        ),
      );

      if (!mounted || saved != true) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weekly budget saved.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isOpeningBudget = false;
        });
      }
    }
  }

  Widget accountHeader(User user) {
    return StreamBuilder<String?>(
      stream: nameStream,
      builder: (context, snapshot) {
        final hasError = snapshot.hasError || nameStream == null;
        final isLoading = !hasError &&
            (snapshot.connectionState == ConnectionState.waiting ||
                snapshot.connectionState == ConnectionState.none);

        final name = hasError ? null : snapshot.data;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF123C25),
                Color(0xFF227447),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFFE5F6BD),
                child: Icon(
                  Icons.person_outline,
                  size: 34,
                  color: Color(0xFF123C25),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                name ?? 'Your account',
                style: const TextStyle(
                  fontSize: 28,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                user.email ?? 'Email unavailable',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Color(0xFFE3F1E6),
                ),
              ),
              const SizedBox(height: 18),
              if (isLoading)
                const LinearProgressIndicator(
                  color: Color(0xFFE5F6BD),
                  backgroundColor: Color(0xFF305F43),
                )
              else if (hasError) ...[
                const Text(
                  'Unable to load your preferred name.',
                  style: TextStyle(color: Colors.white),
                ),
                TextButton.icon(
                  onPressed: retrySettings,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE5F6BD),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ] else
                FilledButton.icon(
                  onPressed: isOpeningName
                      ? null
                      : () => openName(name),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE5F6BD),
                    foregroundColor: const Color(0xFF123C25),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(
                    name == null
                        ? 'Add preferred name'
                        : 'Edit preferred name',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget settingCard({
    required IconData icon,
    required String title,
    required String description,
    required Widget action,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF6E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF176B3A),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Color(0xFF536458),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            action,
          ],
        ),
      ),
    );
  }

  Widget budgetSetting() {
    return StreamBuilder<int?>(
      stream: budgetStream,
      builder: (context, snapshot) {
        if (snapshot.hasError || budgetStream == null) {
          return settingCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Weekly budget',
            description: 'Unable to load your budget setting.',
            action: OutlinedButton.icon(
              onPressed: retrySettings,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.none) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: LinearProgressIndicator(),
          );
        }

        final budgetPence = snapshot.data;

        return settingCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Weekly budget',
          description: budgetPence == null
              ? 'Set a limit for your grocery week.'
              : '${money(budgetPence)} per week · '
                  'Shared with Home and Budget.',
          action: OutlinedButton.icon(
            onPressed: isOpeningBudget
                ? null
                : () => openBudget(budgetPence),
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              budgetPence == null ? 'Set budget' : 'Edit budget',
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text('Please log in to view your profile.'),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            accountHeader(user),
            const SizedBox(height: 28),
            const Text(
              'Your preferences',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            budgetSetting(),
            const SizedBox(height: 16),
            settingCard(
              icon: Icons.lock_outline,
              title: 'Password',
              description: 'Reset your password through an email link.',
              action: OutlinedButton.icon(
                onPressed: user.email == null
                    ? null
                    : () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => ResetPasswordScreen(
                              initialEmail: user.email!,
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.lock_reset),
                label: const Text('Reset password'),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'To sign out, use Log out at the top right.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF536458),
              ),
            ),
          ],
        ),
      ),
    );
  }
}