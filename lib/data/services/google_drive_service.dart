// lib/services/drive_service.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_service.dart';

class DriveBackupResult {
  final bool success;
  final String message;
  final String? fileId;

  DriveBackupResult({
    required this.success,
    required this.message,
    this.fileId,
  });
}

class DriveService {
  // Singleton pattern
  static final DriveService _instance = DriveService._internal();
  factory DriveService() => _instance;
  DriveService._internal();

  final LoginService _loginService = LoginService();
  final String _backupFolderName = 'MiApp_Backups';

  // Subir archivo a Google Drive
  Future<DriveBackupResult> uploadFileToDrive(File file) async {
    try {
      final driveApi = await _loginService.getDriveApi();
      if (driveApi == null) {
        return DriveBackupResult(
          success: false,
          message: 'No has iniciado sesión con Google',
        );
      }

      // Verificar si la carpeta existe, si no, crearla
      String? folderId = await _getFolderIdByName(driveApi, _backupFolderName);
      if (folderId == null) {
        folderId = await _createFolder(driveApi, _backupFolderName);
        if (folderId == null) {
          return DriveBackupResult(
            success: false,
            message: 'No se pudo crear la carpeta de respaldos',
          );
        }
      }

      // Crear el archivo en Drive
      final driveFile = drive.File();
      driveFile.name = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      driveFile.parents = [folderId];

      // Subir el archivo
      final response = await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
      );

      debugPrint('Archivo subido con ID: ${response.id}');
      return DriveBackupResult(
        success: true,
        message: 'Respaldo creado correctamente',
        fileId: response.id,
      );
    } catch (e) {
      debugPrint('Error al subir archivo: $e');
      return DriveBackupResult(
        success: false,
        message: 'Error al crear respaldo: $e',
      );
    }
  }

  // Descargar archivo de Google Drive
  Future<File?> downloadFileFromDrive(String fileId, String localPath) async {
    try {
      final driveApi = await _loginService.getDriveApi();
      if (driveApi == null) {
        return null;
      }

      final drive.Media media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final List<int> dataStore = [];
      await media.stream.forEach((data) {
        dataStore.insertAll(dataStore.length, data);
      });

      final File file = File(localPath);
      await file.writeAsBytes(dataStore);
      return file;
    } catch (e) {
      debugPrint('Error al descargar archivo: $e');
      return null;
    }
  }

  // Crear carpeta en Google Drive
  Future<String?> _createFolder(drive.DriveApi driveApi, String folderName) async {
    final folder = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder';

    try {
      final result = await driveApi.files.create(folder);
      return result.id;
    } catch (e) {
      debugPrint('Error al crear carpeta: $e');
      return null;
    }
  }

  // Obtener ID de carpeta por nombre
  Future<String?> _getFolderIdByName(drive.DriveApi driveApi, String folderName) async {
    try {
      final query = "name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      final result = await driveApi.files.list(q: query);
      if (result.files != null && result.files!.isNotEmpty) {
        return result.files!.first.id;
      }
      return null;
    } catch (e) {
      debugPrint('Error al buscar carpeta: $e');
      return null;
    }
  }

  // Listar respaldos disponibles
  Future<List<drive.File>> listBackups() async {
    try {
      final driveApi = await _loginService.getDriveApi();
      if (driveApi == null) {
        return [];
      }

      final String? folderId = await _getFolderIdByName(driveApi, _backupFolderName);
      if (folderId == null) {
        return [];
      }

      final query = "'$folderId' in parents and trashed = false";
      final result = await driveApi.files.list(q: query);
      return result.files ?? [];
    } catch (e) {
      debugPrint('Error al listar respaldos: $e');
      return [];
    }
  }

  // Programar respaldo automático
  Future<bool> scheduleBackup(String localFilePath, Duration interval) async {
    final prefs = await SharedPreferences.getInstance();
    final lastBackup = prefs.getInt('lastBackup') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastBackup > interval.inMilliseconds) {
      final file = File(localFilePath);
      if (!file.existsSync()) {
        debugPrint('El archivo no existe');
        return false;
      }

      final result = await uploadFileToDrive(file);
      if (result.success) {
        await prefs.setInt('lastBackup', now);
        return true;
      }
    }
    return false;
  }

  // Eliminar respaldo
  Future<bool> deleteBackup(String fileId) async {
    try {
      final driveApi = await _loginService.getDriveApi();
      if (driveApi == null) {
        return false;
      }

      await driveApi.files.delete(fileId);
      return true;
    } catch (e) {
      debugPrint('Error al eliminar respaldo: $e');
      return false;
    }
  }

  // Obtener detalles de un archivo
  Future<drive.File?> getFileDetails(String fileId) async {
    try {
      final driveApi = await _loginService.getDriveApi();
      if (driveApi == null) {
        return null;
      }

      return await driveApi.files.get(fileId) as drive.File;
    } catch (e) {
      debugPrint('Error al obtener detalles del archivo: $e');
      return null;
    }
  }
}