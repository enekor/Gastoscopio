
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
// Cliente HTTP para autenticación
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class AuthStatus {
  final bool isLoading;
  final String message;
  final bool isSuccess;
  final bool isError;

  AuthStatus({
    this.isLoading = false,
    this.message = '',
    this.isSuccess = false,
    this.isError = false,
  });

  factory AuthStatus.initial() => AuthStatus();
  
  factory AuthStatus.loading(String message) => AuthStatus(
    isLoading: true,
    message: message,
  );
  
  factory AuthStatus.success(String message) => AuthStatus(
    message: message,
    isSuccess: true,
  );
  
  factory AuthStatus.error(String message) => AuthStatus(
    message: message,
    isError: true,
  );
}

class LoginService {
  // Singleton pattern
  static final LoginService _instance = LoginService._internal();
  factory LoginService() => _instance;
  LoginService._internal();

  // Inicialización de Google Sign In con los scopes necesarios
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  // Stream para notificar cambios en el usuario actual
  Stream<GoogleSignInAccount?> get onUserChanged => 
      _googleSignIn.onCurrentUserChanged;

  // Obtener usuario actual
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  // Comprobar si hay un usuario activo
  bool get isSignedIn => _googleSignIn.currentUser != null;

  // Verificar si hay un usuario guardado e intentar iniciar sesión silenciosamente
  Future<GoogleSignInAccount?> silentSignIn() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('Error en silentSignIn: $e');
      return null;
    }
  }

  // Iniciar sesión con Google
  Future<AuthStatus> signInWithGoogle() async {
    try {
      // Mostrar el diálogo de selección de cuenta de Google
      final account = await _googleSignIn.signIn();
      
      if (account == null) {
        // El usuario canceló el inicio de sesión
        return AuthStatus.error('Inicio de sesión cancelado');
      }
      
      // Verificar acceso a Drive (opcional)
      final driveStatus = await _verifyDriveAccess(account);
      
      if (driveStatus.isError) {
        return driveStatus;
      }
      
      return AuthStatus.success(
        'Sesión iniciada correctamente con ${account.email}'
      );
    } catch (e) {
      debugPrint('Error en signInWithGoogle: $e');
      return AuthStatus.error('Error al iniciar sesión: $e');
    }
  }

  // Cerrar sesión
  Future<AuthStatus> signOut() async {
    try {
      await _googleSignIn.signOut();
      return AuthStatus.success('Sesión cerrada correctamente');
    } catch (e) {
      debugPrint('Error en signOut: $e');
      return AuthStatus.error('Error al cerrar sesión: $e');
    }
  }

  // Verificar el acceso a Google Drive
  Future<AuthStatus> _verifyDriveAccess(GoogleSignInAccount account) async {
    try {
      final headers = await account.authHeaders;
      final client = GoogleAuthClient(headers);
      final driveApi = drive.DriveApi(client);
      
      // Intentar listar archivos para verificar el acceso
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        pageSize: 10,
      );
      
      return AuthStatus.success(
        'Drive conectado. ${fileList.files?.length ?? 0} archivos encontrados.'
      );
    } catch (e) {
      debugPrint('Error al verificar acceso a Drive: $e');
      // Incluso si hay un error con Drive, el inicio de sesión podría ser válido
      // así que no lo tratamos como un error crítico
      return AuthStatus.success(
        'Sesión iniciada, pero puede haber problemas al acceder a Drive'
      );
    }
  }

  // Obtener una instancia de DriveApi para usar en otras partes de la app
  Future<drive.DriveApi?> getDriveApi() async {
    if (!isSignedIn) return null;
    
    try {
      final headers = await currentUser!.authHeaders;
      final client = GoogleAuthClient(headers);
      return drive.DriveApi(client);
    } catch (e) {
      debugPrint('Error al obtener DriveApi: $e');
      return null;
    }
  }
}