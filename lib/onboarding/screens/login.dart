import 'package:cashly/data/services/login_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
    if (_loginService.isSignedIn) {
      // Si hay un usuario activo, actualizar el estado

      _currentUser = _loginService.currentUser;
    } else {
      // Si no hay usuario activo, dejarlo como null
      _currentUser = null;
    }
  }

  Future<void> _checkExistingUser() async {
    // Intentar iniciar sesión silenciosamente si hay una sesión guardada
    await _loginService.silentSignIn();
    changeLoginStatus();

    // El listener de onUserChanged actualizará la UI
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Iniciando sesión...';
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
      _statusMessage = 'Cerrando sesión...';
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
              // Header con logo y título
              _buildHeader(context),
              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Card principal de información de usuario
                      _buildUserCard(context),
                      const SizedBox(height: 24),

                      // Card de acciones
                      _buildActionsCard(context),
                      const SizedBox(height: 24),

                      // Mensaje de estado si existe
                      if (_statusMessage.isNotEmpty)
                        _buildStatusMessage(context),

                      // Indicador de carga
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
        // Logo
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
          'Bienvenido a Gastoscopio',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Conecta tu cuenta de Google para sincronizar y respaldar tus datos financieros',
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
              // Usuario conectado
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
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Conectado correctamente',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _currentUser!.displayName ?? 'Usuario',
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
              // Sin usuario conectado
              Icon(
                Icons.cloud_off,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Sin cuenta conectada',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia sesión con Google para acceder a funciones de respaldo y sincronización',
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
              // Botón de inicio de sesión
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleSignIn,
                icon: const Icon(Icons.login),
                label: const Text('Iniciar sesión con Google'),
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
                'Opcional: Puedes continuar sin cuenta, pero no tendrás acceso a funciones de respaldo.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton(
                child: Text('Continuar sin iniciar sesion'),
                onPressed: widget.onLoginOk,
              )
            ] else ...[
              // Opciones cuando está conectado
              ElevatedButton.icon(
                onPressed: widget.onLoginOk,
                icon: const Icon(Icons.navigate_next),
                label: const Text('Continuar al siguiente paso'),
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
                label: const Text('Cerrar sesión'),
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
