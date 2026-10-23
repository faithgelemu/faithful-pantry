import 'package:flutter/material.dart';

import 'services/settings_service.dart';

class PreferredNameScreen extends StatefulWidget {
  const PreferredNameScreen({
    super.key,
    this.currentName,
  });

  final String? currentName;

  @override
  State<PreferredNameScreen> createState() =>
      _PreferredNameScreenState();
}

class _PreferredNameScreenState extends State<PreferredNameScreen> {
  final formKey = GlobalKey<FormState>();
  final service = SettingsService();

  late final TextEditingController nameController;

  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.currentName ?? '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> saveName() async {
    if (isSaving || !formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      await service.savePreferredName(nameController.text);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ArgumentError catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.message?.toString() ?? 'Check your name.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Unable to save your name. Check your connection '
            'and try again.';
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
    return PopScope(
      canPop: !isSaving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Preferred name'),
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
                    const Text(
                      'What should we call you?',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Use the name you would like to see on Home. '
                      'Leave it blank to use a general welcome.',
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: nameController,
                      enabled: !isSaving,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => saveName(),
                      decoration: const InputDecoration(
                        labelText: 'Preferred name',
                        hintText: 'For example, Faith',
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().runes.length > 40) {
                          return 'Use up to 40 characters.';
                        }

                        return null;
                      },
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isSaving ? null : saveName,
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save name'),
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