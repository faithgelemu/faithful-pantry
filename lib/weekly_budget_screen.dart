
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'services/settings_service.dart';

class WeeklyBudgetScreen extends StatefulWidget {
  const WeeklyBudgetScreen({
    super.key,
    this.currentBudgetPence,
  });

  final int? currentBudgetPence;

  @override
  State<WeeklyBudgetScreen> createState() => _WeeklyBudgetScreenState();
}

class _WeeklyBudgetScreenState extends State<WeeklyBudgetScreen> {
  final formKey = GlobalKey<FormState>();
  final service = SettingsService();

  late final TextEditingController budgetController;

  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    final current = widget.currentBudgetPence;

    budgetController = TextEditingController(
      text: current == null ? '' : (current / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    budgetController.dispose();
    super.dispose();
  }

  int? amountInPence(String value) {
    final text = value.trim();

    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
      return null;
    }

    final parts = text.split('.');
    final pounds = int.tryParse(parts.first);
    final pence = parts.length == 2
        ? int.tryParse(parts[1].padRight(2, '0'))
        : 0;

    if (pounds == null || pence == null) return null;

    return pounds * 100 + pence;
  }

  Future<void> saveBudget() async {
    if (isSaving || !formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      await service.saveWeeklyBudgetPence(
        amountInPence(budgetController.text)!,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseException catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = switch (error.code) {
          'permission-denied' =>
            'Unable to save. Check your login and access rules.',
          'unavailable' =>
            'The database is unavailable. Check your connection.',
          _ => 'Unable to save your budget. Please try again.',
        };
      });
    } on StateError catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.message;
      });
    } on ArgumentError catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.message?.toString() ?? 'Check the amount.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !isSaving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Weekly budget'),
          automaticallyImplyLeading: !isSaving,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Set your weekly grocery budget',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This limit is reused each week. Changing it '
                      'does not change your purchase history.',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: budgetController,
                      enabled: !isSaving,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => saveBudget(),
                      decoration: const InputDecoration(
                        labelText: 'Weekly budget',
                        prefixText: '£ ',
                        hintText: '30.00',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final amount = amountInPence(value ?? '');

                        if (amount == null || amount > 1000000) {
                          return 'Enter an amount from 0 to 10000, '
                              'with up to two decimal places.';
                        }

                        return null;
                      },
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isSaving ? null : saveBudget,
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save budget'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
