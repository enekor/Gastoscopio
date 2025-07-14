import 'package:cashly/data/services/login_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cashly/l10n/app_localizations.dart';

class GoogleLoginScreen extends StatefulWidget {
  const GoogleLoginScreen({super.key, required this.onLoginOk});

  final Function() onLoginOk;

  @override
  State<GoogleLoginScreen> createState() => _GoogleLoginScreenState();
}

class _GoogleLoginScreenState extends State<GoogleLoginScreen> {
  final LoginService _loginService = LoginService();
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isError = false;
  GoogleSignInAccount? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
  }

  void changeLoginStatus() {
    setState(() {
      if (_loginService.isSignedIn) {
        _currentUser = _loginService.currentUser;
      } else {
        _currentUser = null;
      }
    });
  }

  Future<void> _checkExistingUser() async {
    await _loginService.silentSignIn();
    changeLoginStatus();
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = AppLocalizations.of(context).signingIn;
      _isError = false;
    });

    final status = await _loginService.signIn();
    changeLoginStatus();

    setState(() {
      _isLoading = false;
      _statusMessage = status.message;
      _isError = status.isError;
    });
  }

  Future<void> _handleSignOut() async {
    setState(() {
      _isLoading = true;
      _statusMessage = AppLocalizations.of(context).signingOut;
      _isError = false;
    });

    final status = await _loginService.signOut();

    setState(() {
      _isLoading = false;
      _statusMessage = status.message;
      _isError = status.isError;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildHeader(context),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildUserCard(context),
                      const SizedBox(height: 24),
                      _buildActionsCard(context),
                      const SizedBox(height: 24),
                      if (_statusMessage.isNotEmpty)
                        _buildStatusMessage(context),
                      if (_isLoading) ...[
                        const SizedBox(height: 24),
                        const CircularProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.account_circle,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context).welcomeToApp,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).connectGoogleAccount,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary.withAlpha(25),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withAlpha(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (_currentUser != null) ...[
              CircleAvatar(
                backgroundImage:
                    _currentUser!.photoUrl != null
                        ? NetworkImage(_currentUser!.photoUrl!)
                        : null,
                radius: 40,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withAlpha(25),
                child:
                    _currentUser!.photoUrl == null
                        ? Icon(
                          Icons.person,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        )
                        : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).correctlyConnected,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _currentUser!.displayName ?? AppLocalizations.of(context).user,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                _currentUser!.email,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Icon(
                Icons.cloud_off,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).noAccountConnected,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).loginForBackupSync,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondary.withAlpha(25),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withAlpha(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentUser == null) ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleSignIn,
                icon: const Icon(Icons.login),
                label: Text(AppLocalizations.of(context).signInWithGoogle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).optionalLogin,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onLoginOk,
                child: Text(AppLocalizations.of(context).continueWithoutLogin),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: widget.onLoginOk,
                icon: const Icon(Icons.navigate_next),
                label: Text(AppLocalizations.of(context).continueToNextStep),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _handleSignOut,
                icon: const Icon(Icons.logout),
                label: Text(AppLocalizations.of(context).signOut),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            _isError
                ? Theme.of(context).colorScheme.errorContainer
                : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _isError
                  ? Theme.of(context).colorScheme.error.withAlpha(50)
                  : Theme.of(context).colorScheme.primary.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isError ? Icons.error_outline : Icons.check_circle_outline,
            color:
                _isError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    _isError
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
