import 'package:flutter/material.dart';

enum AppLanguage {
  japanese,
  english,
  simplifiedChinese;

  Locale get locale => switch (this) {
    AppLanguage.japanese => const Locale('ja'),
    AppLanguage.english => const Locale('en'),
    AppLanguage.simplifiedChinese => const Locale('zh', 'CN'),
  };
}

AppLanguage appLanguageFromStorageName(Object? value) {
  return AppLanguage.values.firstWhere(
    (language) => language.name == value,
    orElse: () => AppLanguage.japanese,
  );
}
