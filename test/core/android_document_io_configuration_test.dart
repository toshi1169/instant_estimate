import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Android document I/O configuration', () {
    test('required document plugins remain declared', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();

      for (final dependency in [
        'share_plus:',
        'file_selector:',
        'printing:',
        'pdf:',
        'excel_plus:',
      ]) {
        expect(pubspec, contains(dependency), reason: dependency);
      }
    });

    test('Android does not request broad legacy storage access', () {
      final manifests = Directory('android')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('AndroidManifest.xml'));

      for (final manifest in manifests) {
        final source = manifest.readAsStringSync();
        expect(
          source,
          isNot(contains('android.permission.READ_EXTERNAL_STORAGE')),
          reason: manifest.path,
        );
        expect(
          source,
          isNot(contains('android.permission.WRITE_EXTERNAL_STORAGE')),
          reason: manifest.path,
        );
        expect(
          source,
          isNot(contains('android.permission.MANAGE_EXTERNAL_STORAGE')),
          reason: manifest.path,
        );
      }
    });

    test('PDF and backup exports use the platform share sheet', () {
      final pdfShare = File(
        'lib/features/estimate/application/estimate_pdf_share.dart',
      ).readAsStringSync();
      final backupShare = File(
        'lib/features/backup/application/backup_file_export.dart',
      ).readAsStringSync();

      expect(pdfShare, contains('SharePlus.instance.share'));
      expect(pdfShare, contains("mimeType: 'application/pdf'"));
      expect(pdfShare, contains('fileNameOverrides: [fileName]'));
      expect(backupShare, contains('SharePlus.instance.share'));
      expect(backupShare, contains('.genbacalc'));
      expect(backupShare, contains('fileNameOverrides: [fileName]'));
    });

    test('backup import uses the platform picker and validates its payload', () {
      final backupImport = File(
        'lib/features/backup/application/backup_file_import.dart',
      ).readAsStringSync();

      expect(backupImport, contains('openFile('));
      expect(backupImport, contains("extensions: <String>['genbacalc']"));
      expect(
        backupImport,
        contains('maximumBackupFileBytes = 20 * 1024 * 1024'),
      );
      expect(backupImport, contains("root['format']"));
      expect(backupImport, contains("root['backupVersion']"));
    });

    test('restore journal remains an atomic app-internal Android file', () {
      final activity = File(
        'android/app/src/main/kotlin/'
        'com/matsumotoboundary/constructioncalc/MainActivity.kt',
      ).readAsStringSync();

      expect(
        activity,
        contains(
          'AtomicFile(filesDir.resolve("backup_restore_journal.json"))',
        ),
      );
      expect(activity, contains('stream.fd.sync()'));
      expect(activity, contains('journalFile.finishWrite(stream)'));
      expect(activity, contains('journalFile::failWrite'));
      expect(activity, isNot(contains('getExternalStorageDirectory')));
    });
  });
}
