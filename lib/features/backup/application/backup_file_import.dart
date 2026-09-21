import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kDebugMode;

import '../domain/backup_snapshot.dart';

const maximumBackupFileBytes = 20 * 1024 * 1024;

enum BackupImportFailure {
  pickerFailed,
  readFailed,
  tooLarge,
  invalidUtf8,
  malformedJson,
  wrongFileType,
  wrongFormat,
  unsupportedVersion,
  invalidData,
}

class BackupImportException implements Exception {
  const BackupImportException(this.failure, [this.cause]);

  final BackupImportFailure failure;
  final Object? cause;
}

typedef BackupFilePicker = Future<XFile?> Function();

Future<XFile?> pickBackupFile() async {
  const backupType = XTypeGroup(
    label: 'GenbaCalc backup',
    extensions: <String>['genbacalc'],
    mimeTypes: <String>['application/json', 'application/octet-stream'],
    // iOS does not filter by extension. public.data keeps the picker usable
    // without registering an app-wide UTType; the payload is checked below.
    uniformTypeIdentifiers: <String>['public.data'],
  );
  _debugBackupImport('PICKER open');
  try {
    final file = await openFile(
      acceptedTypeGroups: const <XTypeGroup>[backupType],
    );
    _debugBackupImport(
      'PICKER result null=${file == null}'
      '${file == null ? '' : ' name=${file.name} path=${file.path} mimeType=${file.mimeType}'}',
    );
    return file;
  } catch (error, stackTrace) {
    _debugBackupImport(
      'PICKER error type=${error.runtimeType} message=$error\n$stackTrace',
    );
    throw BackupImportException(BackupImportFailure.pickerFailed, error);
  }
}

Future<BackupSnapshot> readBackupFile(
  XFile file, {
  int maximumBytes = maximumBackupFileBytes,
}) async {
  _debugBackupImport(
    'READ start name=${file.name} path=${file.path} mimeType=${file.mimeType}',
  );
  _debugBackupImport('EXTENSION check start');
  if (_hasDifferentExplicitExtension(file)) {
    _debugBackupImport('EXTENSION rejected name=${file.name}');
    throw const BackupImportException(BackupImportFailure.wrongFileType);
  }
  _debugBackupImport('EXTENSION accepted');

  int length;
  try {
    length = await file.length();
    _debugBackupImport('LENGTH success bytes=$length');
  } catch (error, stackTrace) {
    _debugBackupImport(
      'LENGTH error type=${error.runtimeType} message=$error\n$stackTrace',
    );
    throw BackupImportException(BackupImportFailure.readFailed, error);
  }
  if (length > maximumBytes) {
    throw const BackupImportException(BackupImportFailure.tooLarge);
  }

  Uint8List bytes;
  try {
    _debugBackupImport('BYTES read start');
    bytes = await file.readAsBytes();
    _debugBackupImport('BYTES read success count=${bytes.length}');
  } catch (error, stackTrace) {
    _debugBackupImport(
      'BYTES error type=${error.runtimeType} message=$error\n$stackTrace',
    );
    throw BackupImportException(BackupImportFailure.readFailed, error);
  }
  if (bytes.length > maximumBytes) {
    throw const BackupImportException(BackupImportFailure.tooLarge);
  }

  String source;
  try {
    _debugBackupImport('UTF8 decode start');
    source = utf8.decode(bytes, allowMalformed: false);
    _debugBackupImport('UTF8 decode success characters=${source.length}');
  } on FormatException catch (error) {
    _debugBackupImport('UTF8 error type=${error.runtimeType} message=$error');
    throw BackupImportException(BackupImportFailure.invalidUtf8, error);
  }

  Object? decoded;
  try {
    _debugBackupImport('JSON parse start');
    decoded = jsonDecode(source);
    _debugBackupImport('JSON parse success type=${decoded.runtimeType}');
  } on FormatException catch (error) {
    _debugBackupImport('JSON error type=${error.runtimeType} message=$error');
    throw BackupImportException(BackupImportFailure.malformedJson, error);
  }
  if (decoded is! Map<Object?, Object?> ||
      decoded.keys.any((key) => key is! String)) {
    throw const BackupImportException(BackupImportFailure.invalidData);
  }
  final root = decoded.map((key, value) => MapEntry(key as String, value));
  if (root['format'] != BackupSnapshot.formatIdentifier) {
    throw const BackupImportException(BackupImportFailure.wrongFormat);
  }
  final version = root['backupVersion'];
  if (version is int && version > BackupSnapshot.currentVersion) {
    throw const BackupImportException(BackupImportFailure.unsupportedVersion);
  }

  try {
    final snapshot = BackupSnapshot.fromJson(root);
    _debugBackupImport('VALIDATOR success');
    return snapshot;
  } on UnsupportedBackupVersionException catch (error) {
    throw BackupImportException(BackupImportFailure.unsupportedVersion, error);
  } on BackupValidationException catch (error) {
    throw BackupImportException(BackupImportFailure.invalidData, error);
  }
}

void _debugBackupImport(String message) {
  if (kDebugMode) debugPrint('[BackupImport] $message');
}

bool _hasDifferentExplicitExtension(XFile file) {
  final trimmed = file.name.trim().toLowerCase();
  final separator = trimmed.lastIndexOf('.');
  if (separator < 0 || separator == trimmed.length - 1) return false;
  final extension = trimmed.substring(separator + 1);
  if (extension == 'genbacalc') return false;

  // Android DocumentsUI can preserve the selected .genbacalc payload while
  // file_selector copies it into the app cache with a .bin name derived from
  // application/octet-stream. The payload still passes every format and data
  // validation below before it can be restored.
  final isAndroidPickerBinary =
      defaultTargetPlatform == TargetPlatform.android &&
      extension == 'bin' &&
      file.mimeType?.trim().toLowerCase() == 'application/octet-stream';
  return !isAndroidPickerBinary;
}
