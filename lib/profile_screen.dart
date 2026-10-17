import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  bool isOpeningBudget = false;

  @override
  void initState() {
    super.initState();

    try {
      budgetStream = settingsService.watchWeeklyBudgetPence();
    } on StateError {
      budgetStream = null;
    }
  }

  String money(int pence) {
    return '£${(pence / 100).toStringAsFixed(2)}';
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

  void retryBudget() {
    try {
      final stream = settingsService.watchWeeklyBudgetPence();

      setState(() {
        budgetStream = stream;
      });
    } on StateError {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to access your settings.'),
        ),
      );
    }
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
            const Text(
              'Your account',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    const Text('Signed in as'),
                    const SizedBox(height: 6),
                    SelectableText(
                      user.email ?? 'Email unavailable',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<int?>(
              stream: budgetStream,
              builder: (context, snapshot) {
                if (snapshot.hasError || budgetStream == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Unable to load your budget setting.'),
                      TextButton.icon(
                        onPressed: retryBudget,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  );
                }

                if (snapshot.connectionState ==
                        ConnectionState.waiting ||
                    snapshot.connectionState == ConnectionState.none) {
                  return const LinearProgressIndicator();
                }

                final budgetPence = snapshot.data;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weekly grocery budget',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          budgetPence == null
                              ? 'No weekly budget set.'
                              : 'Current limit: ${money(budgetPence)}',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This setting is shared with Home and Budget.',
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: isOpeningBudget
                              ? null
                              : () => openBudget(budgetPence),
                          icon: const Icon(Icons.edit_outlined),
                          label: Text(
                            budgetPence == null
                                ? 'Set weekly budget'
                                : 'Edit weekly budget',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Use the Log out button at the top right '
              'to sign out of this account.',
            ),
          ],
        ),
      ),
    );
  }
}