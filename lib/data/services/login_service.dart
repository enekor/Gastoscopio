import 'dart:io';

import 'package:cashly/data/services/log_file_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:cashly/data/services/sqlite_service.dart';

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

  factory AuthStatus.loading(String message) =>
      AuthStatus(isLoading: true, message: message);

  factory AuthStatus.success(String message) =>
      AuthStatus(message: message, isSuccess: true);

  factory AuthStatus.error(String message) =>
      AuthStatus(message: message, isError: true);
}

class LoginService extends ChangeNotifier {
  // Instancia estática privada
  static final LoginService _instance = LoginService._internal();

  // Constructor factory que retorna la instancia
  factory LoginService() {
    return _instance;
  }

  // Constructor privado
  LoginService._internal() {
    _initialize();
  }
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  // Estados del servicio
  GoogleSignInAccount? _currentUser;
  bool _isLoading = false;
  String _statusMessage = '';
  bool _isSignedIn = false;

  // Getters públicos
  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;
  bool get isSignedIn => _isSignedIn;

  // Constructor

  // Inicialización del servicio
  void _initialize() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser = account;
      _isSignedIn = account != null;
      notifyListeners();
    });
    _googleSignIn.signInSilently();
  }

  Future<void> silentSignIn() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      _isSignedIn = _currentUser != null;
    } catch (error) {
      LogFileService().appendLog('Silent sign-in error: $error');
      print('Error al iniciar sesión silenciosamente: $error');
    }
  }

  // Método para iniciar sesión
  Future<AuthStatus> signIn() async {
    _setLoading(true);
    _setStatusMessage('Iniciando sesión...');

    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        _currentUser = account;
        _isSignedIn = true;
        _setStatusMessage('Sesión iniciada correctamente');
        notifyListeners();
        return AuthStatus.success('Sesión iniciada correctamente');
      } else {
        _setStatusMessage('Inicio de sesión cancelado');
        return AuthStatus.error('Inicio de sesión cancelado');
      }
    } catch (error) {
      _setStatusMessage('Error al iniciar sesión: $error');
      LogFileService().appendLog('Error al iniciar sesión con Google: $error');
      print('Error al iniciar sesión con Google: $error');
      return AuthStatus.error('Error al iniciar sesión: $error');
    } finally {
      _setLoading(false);
    }
  }

  // Método para cerrar sesión
  Future<AuthStatus> signOut() async {
    _setLoading(true);
    _setStatusMessage('Cerrando sesión...');

    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _isSignedIn = false;
      _setStatusMessage('Sesión cerrada correctamente');
      notifyListeners();
      return AuthStatus.success('Sesión cerrada correctamente');
    } catch (error) {
      _setStatusMessage('Error al cerrar sesión: $error');
      LogFileService().appendLog('Error al cerrar sesión: $error');
      print('Error al cerrar sesión: $error');
      return AuthStatus.error('Error al cerrar sesión: $error');
    } finally {
      _setLoading(false);
    }
  }

  // Método principal para verificar y descargar backup existente
  Future<String> checkExistingBackup() async {
    await silentSignIn();
    // Asegurarse de que el usuario esté autenticado
    if (!_isSignedIn) {
      _setStatusMessage('No hay sesión iniciada');
      return "No hay sesión iniciada";
    }

    _setLoading(true);
    _setStatusMessage('Buscando backup existente...');

    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        _setStatusMessage('Error al acceder a Google Drive');
        return "Error al acceder a Google Drive";
      }

      // Buscar el archivo cashly_database.db en Google Drive
      final fileId = await _findDatabaseFile(driveApi);

      if (fileId != null) {
        _setStatusMessage('Backup encontrado, descargando...');

        // Obtener la ruta local donde guardar el archivo
        final localPath = await _getLocalDatabasePath();

        // Descargar el archivo desde Google Drive
        final success = await _downloadDatabaseFile(
          driveApi,
          fileId,
          localPath,
        );

        if (success) {
          _setStatusMessage('Backup restaurado correctamente');
          return "Backup restaurado correctamente";
        } else {
          _setStatusMessage('Error al descargar el backup');
          return "Error al descargar el backup";
        }
      } else {
        _setStatusMessage('No se encontró backup previo');
        return "No se encontró backup previo";
      }
    } catch (e) {
      _setStatusMessage('Error al verificar backup: $e');
      LogFileService().appendLog('Error al verificar backup: $e');
      return "Error al verificar backup: $e";
    } finally {
      _setLoading(false);
    }
  }

  // Método para subir la base de datos a Google Drive
  Future<bool> uploadDatabase() async {
    await silentSignIn(); // Asegurarse de que el usuario esté autenticado
    if (!_isSignedIn) {
      _setStatusMessage('No hay sesión iniciada');
      return false;
    }

    _setLoading(true);
    _setStatusMessage('Subiendo backup...');

    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) {
        _setStatusMessage('Error al acceder a Google Drive');
        return false;
      }

      // Obtener la ruta local del archivo de base de datos
      final localPath = await _getLocalDatabasePath();
      final file = File(localPath);

      if (!file.existsSync()) {
        _setStatusMessage('No existe el archivo de base de datos local');
        return false;
      }

      // Verificar si ya existe el archivo en Drive para actualizarlo
      final existingFileId = await _findDatabaseFile(driveApi);

      bool success;
      if (existingFileId != null) {
        // Actualizar archivo existente
        success = await _updateDatabaseFile(driveApi, existingFileId, file);
        _setStatusMessage(
          success
              ? 'Backup actualizado correctamente'
              : 'Error al actualizar backup',
        );
      } else {
        // Crear nuevo archivo
        success = await _createDatabaseFile(driveApi, file);
        _setStatusMessage(
          success ? 'Backup creado correctamente' : 'Error al crear backup',
        );
      }

      return success;
    } catch (e) {
      _setStatusMessage('Error al subir backup: $e');
      LogFileService().appendLog('Error en uploadDatabase: $e');
      print('Error en uploadDatabase: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Obtener API de Drive
  Future<drive.DriveApi?> _getDriveApi() async {
    if (_currentUser == null) return null;

    try {
      final headers = await _currentUser!.authHeaders;
      final client = GoogleAuthClient(headers);
      return drive.DriveApi(client);
    } catch (e) {
      print('Error al obtener DriveApi: $e');
      LogFileService().appendLog('Error al obtener DriveApi: $e');
      return null;
    }
  }

  // Buscar el archivo cashly_database.db en Google Drive
  Future<String?> _findDatabaseFile(drive.DriveApi driveApi) async {
    try {
      final query = "name = 'cashly_database.db' and trashed = false";
      final result = await driveApi.files.list(
        q: query,
        spaces: 'appDataFolder',
      );

      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first.id;
      }
      return null;
    } catch (e) {
      LogFileService().appendLog('Error al buscar archivo: $e');
      print('Error al buscar archivo: $e');
      return null;
    }
  }

  // Obtener la ruta local del archivo de base de datos
  Future<String> _getLocalDatabasePath() async {
    // Usar el path real de la base de datos desde SqliteService
    return await SqliteService().getDatabasePath();
  }

  // Descargar archivo de base de datos desde Google Drive
  Future<bool> _downloadDatabaseFile(
    drive.DriveApi driveApi,
    String fileId,
    String localPath,
  ) async {
    try {
      final drive.Media media =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final List<int> dataStore = [];
      await media.stream.forEach((data) {
        dataStore.insertAll(dataStore.length, data);
      });

      final file = File(localPath);
      await file.writeAsBytes(dataStore);
      return true;
    } catch (e) {
      print('Error al descargar archivo: $e');
      LogFileService().appendLog('Error al descargar archivo: $e');
      return false;
    }
  }

  // Crear nuevo archivo de base de datos en Google Drive
  Future<bool> _createDatabaseFile(
    drive.DriveApi driveApi,
    File localFile,
  ) async {
    try {
      final driveFile = drive.File()
        ..name = 'cashly_database.db'
        ..parents = ['appDataFolder']; // Usar appDataFolder para privacidad

      await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(localFile.openRead(), localFile.lengthSync()),
      );

      return true;
    } catch (e) {
      print('Error al crear archivo: $e');
      LogFileService().appendLog('Error al crear archivo: $e');
      return false;
    }
  }

  // Actualizar archivo existente de base de datos en Google Drive
  Future<bool> _updateDatabaseFile(
    drive.DriveApi driveApi,
    String fileId,
    File localFile,
  ) async {
    try {
      final driveFile = drive.File()..modifiedTime = DateTime.now();

      await driveApi.files.update(
        driveFile,
        fileId,
        uploadMedia: drive.Media(localFile.openRead(), localFile.lengthSync()),
      );

      return true;
    } catch (e) {
      print('Error al actualizar archivo: $e');
      LogFileService().appendLog('Error al actualizar archivo: $e');
      return false;
    }
  }

  // Métodos auxiliares para manejar estado
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setStatusMessage(String message) {
    _statusMessage = message;
    notifyListeners();
  }

  // Método adicional para verificar si existe backup sin descargarlo
  Future<bool> hasExistingBackup() async {
    if (!_isSignedIn) return false;

    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      final fileId = await _findDatabaseFile(driveApi);
      return fileId != null;
    } catch (e) {
      print('Error al verificar existencia de backup: $e');
      LogFileService().appendLog('Error al verificar existencia de backup: $e');
      return false;
    }
  }

  // Método para obtener información del backup
  Future<Map<String, dynamic>?> getBackupInfo() async {
    if (!_isSignedIn) return null;

    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final query = "name = 'cashly_database.db' and trashed = false";
      final result = await driveApi.files.list(
        q: query,
        spaces: 'appDataFolder',
        $fields: 'files(id,name,size,modifiedTime)',
      );

      if (result.files != null && result.files!.isNotEmpty) {
        final file = result.files!.first;
        return {
          'id': file.id,
          'name': file.name,
          'size': file.size,
          'modifiedTime': file.modifiedTime?.toIso8601String(),
        };
      }
      return null;
    } catch (e) {
      print('Error al obtener información del backup: $e');
      LogFileService().appendLog('Error al obtener información del backup: $e');
      return null;
    }
  }

  Future<bool> silentLogin() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      return _currentUser != null;
    } catch (e) {
      debugPrint('Silent login error: $e');
      LogFileService().appendLog('Silent login error: $e');
      return false;
    }
  }
}
