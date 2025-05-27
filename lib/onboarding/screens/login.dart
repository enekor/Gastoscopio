// lib/screens/google_login_screen.dart

import 'package:cashly/data/services/login_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleLoginScreen extends StatefulWidget {
  @override
  _GoogleLoginScreenState createState() => _GoogleLoginScreenState();

  const GoogleLoginScreen({Key? key, required this.onLoginOk})
    : super(key: key);
  final Function() onLoginOk;
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
      setState(() {
        _currentUser = _loginService.currentUser;
      });
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_currentUser?.displayName ?? 'Algo'),
            // Estado del usuario (conectado/desconectado)
            _currentUser != null
                ? Column(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(
                        _currentUser!.photoUrl ?? '',
                      ),
                      radius: 30,
                      backgroundColor: Colors.grey[200],
                      child:
                          _currentUser!.photoUrl == null
                              ? Icon(Icons.person, size: 30, color: Colors.grey)
                              : null,
                    ),
                    SizedBox(height: 8),
                    Text('Conectado como:', style: TextStyle(fontSize: 16)),
                    Text(
                      _currentUser!.displayName ?? 'Usuario',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _currentUser!.email,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                )
                : Text(
                  'No has iniciado sesión',
                  style: TextStyle(fontSize: 20),
                ),

            SizedBox(height: 30),

            // Botón de inicio de sesión con Google
            if (_currentUser == null)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleSignIn,
                icon: Icon(Icons.login),
                label: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Text(
                    'Iniciar sesión con Google',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

            // Botón para cerrar sesión
            if (_currentUser != null)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _handleSignOut,
                icon: Icon(Icons.logout),
                label: Text('Cerrar sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                ),
              ),

            SizedBox(height: 20),

            // Botón para ir a la pantalla de respaldos (solo si está conectado)
            if (_currentUser != null)
              ElevatedButton.icon(
                onPressed: widget.onLoginOk,
                icon: Icon(Icons.navigate_next_rounded),
                label: Text('Siguiente paso'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),

            SizedBox(height: 20),

            // Mensaje de estado
            if (_statusMessage.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isError ? Colors.red[100] : Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _isError ? Colors.red[800] : Colors.green[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Indicador de carga
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
