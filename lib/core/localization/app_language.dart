import 'package:flutter/material.dart';

enum AppLanguage {
  japanese,
  english;

  Locale get locale => switch (this) {
    AppLanguage.japanese => const Locale('ja'),
    AppLanguage.english => const Locale('en'),
  };
}

AppLanguage appLanguageFromStorageName(Object? value) {
  return AppLanguage.values.firstWhere(
    (language) => language.name == value,
    orElse: () => AppLanguage.japanese,
  );
}
