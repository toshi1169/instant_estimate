import 'dart:convert';

import 'backup_snapshot.dart';

enum BackupRestoreJournalPhase { prepared, applying, committed }

class BackupRestoreJournal {
  const BackupRestoreJournal({
    required this.phase,
    required this.createdAt,
    required this.previous,
    required this.incoming,
  });

  static const currentVersion = 1;

  final BackupRestoreJournalPhase phase;
  final DateTime createdAt;
  final BackupSnapshot previous;
  final BackupSnapshot incoming;

  BackupRestoreJournal copyWith({BackupRestoreJournalPhase? phase}) {
    return BackupRestoreJournal(
      phase: phase ?? this.phase,
      createdAt: createdAt,
      previous: previous,
      incoming: incoming,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'version': currentVersion,
    'phase': phase.name,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'previous': previous.toJson(),
    'incoming': incoming.toJson(),
  };

  String encode() => jsonEncode(toJson());

  factory BackupRestoreJournal.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<Object?, Object?> ||
        decoded.keys.any((key) => key is! String)) {
      throw const BackupValidationException(r'$journal: must be an object');
    }
    return BackupRestoreJournal.fromJson(
      decoded.map((key, value) => MapEntry(key as String, value)),
    );
  }

  factory BackupRestoreJournal.fromJson(Map<String, Object?> json) {
    const expected = {'version', 'phase', 'createdAt', 'previous', 'incoming'};
    if (json.keys.toSet().difference(expected).isNotEmpty ||
        expected.difference(json.keys.toSet()).isNotEmpty) {
      throw const BackupValidationException(r'$journal: invalid keys');
    }
    if (json['version'] != currentVersion) {
      throw const BackupValidationException(r'$journal.version: unsupported');
    }
    final phaseName = json['phase'];
    final phase = BackupRestoreJournalPhase.values
        .where((value) => value.name == phaseName)
        .firstOrNull;
    if (phase == null) {
      throw const BackupValidationException(r'$journal.phase: invalid');
    }
    final createdAtRaw = json['createdAt'];
    final createdAt = createdAtRaw is String
        ? DateTime.tryParse(createdAtRaw)
        : null;
    if (createdAt == null ||
        !createdAt.isUtc ||
        !(createdAtRaw as String).endsWith('Z')) {
      throw const BackupValidationException(r'$journal.createdAt: invalid');
    }
    return BackupRestoreJournal(
      phase: phase,
      createdAt: createdAt,
      previous: BackupSnapshot.fromJson(_map(json['previous'], 'previous')),
      incoming: BackupSnapshot.fromJson(_map(json['incoming'], 'incoming')),
    );
  }
}

Map<String, Object?> _map(Object? value, String field) {
  if (value is! Map<Object?, Object?> ||
      value.keys.any((key) => key is! String)) {
    throw BackupValidationException(
      r'$journal.'
      '$field: invalid',
    );
  }
  return value.map((key, value) => MapEntry(key as String, value));
}
