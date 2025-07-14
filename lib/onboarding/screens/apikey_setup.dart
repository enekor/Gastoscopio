import 'package:cashly/modules/settings.dart/widgets/apikey-generator.dart';
import 'package:flutter/material.dart';
import 'package:cashly/l10n/app_localizations.dart';

class ApiKeySetupScreen extends StatefulWidget {
  final VoidCallback onApiKeySet;

  const ApiKeySetupScreen({Key? key, required this.onApiKeySet})
    : super(key: key);

  @override
  State<ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends State<ApiKeySetupScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppLocalizations.of(context).configureGeminiApiKey,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).apiKeyRequired,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const ApiKeyGenerator(),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: widget.onApiKeySet,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(AppLocalizations.of(context).continueAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
