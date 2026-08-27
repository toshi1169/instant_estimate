import 'dart:typed_data';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';

import '../domain/backup_snapshot.dart';

const genbaCalcBackupMimeType = 'application/json';

typedef BackupBytesSharer =
    Future<void> Function({
      required Uint8List bytes,
      required String fileName,
      required String subject,
      Rect? sharePositionOrigin,
    });

class BackupExportDocument {
  const BackupExportDocument({
    required this.snapshot,
    required this.fileName,
    required this.bytes,
  });

  final BackupSnapshot snapshot;
  final String fileName;
  final Uint8List bytes;
}

BackupExportDocument buildBackupExportDocument(BackupSnapshot snapshot) {
  return BackupExportDocument(
    snapshot: snapshot,
    fileName: backupFileName(snapshot.createdAt.toLocal()),
    bytes: snapshot.encodeUtf8(),
  );
}

String backupFileName(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return 'GenbaCalc_Backup_'
      '${value.year.toString().padLeft(4, '0')}'
      '${two(value.month)}${two(value.day)}_'
      '${two(value.hour)}${two(value.minute)}${two(value.second)}.genbacalc';
}

Future<void> shareBackupBytes({
  required Uint8List bytes,
  required String fileName,
  required String subject,
  Rect? sharePositionOrigin,
}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: genbaCalcBackupMimeType)],
      fileNameOverrides: [fileName],
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
