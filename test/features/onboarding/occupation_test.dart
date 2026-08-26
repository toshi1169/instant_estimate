import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_language.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/onboarding/domain/occupation.dart';

void main() {
  test('7業種は安定キーを持ち旧保存名も復元できる', () {
    expect(Occupation.values, hasLength(7));
    expect(Occupation.values.map((value) => value.storageKey), [
      'buildingSupervisor',
      'civilSupervisor',
      'foundation',
      'exterior',
      'interior',
      'multiTrade',
      'other',
    ]);
    for (final occupation in Occupation.values) {
      expect(Occupation.fromStoredValue(occupation.storageKey), occupation);
      expect(Occupation.fromStoredValue(occupation.legacyLabel), occupation);
    }
    expect(Occupation.fromStoredValue(null), isNull);
    expect(Occupation.fromStoredValue('unknown'), isNull);
  });

  test('業種設定文言と自社情報ショートカット文言を8言語で明示する', () {
    const expectedMainOccupation = {
      AppLanguage.japanese: '主な業種',
      AppLanguage.english: 'Main occupation',
      AppLanguage.simplifiedChinese: '主要行业',
      AppLanguage.traditionalChinese: '主要行業',
      AppLanguage.vietnamese: 'Ngành nghề chính',
      AppLanguage.indonesian: 'Bidang pekerjaan utama',
      AppLanguage.filipino: 'Pangunahing larangan ng trabaho',
      AppLanguage.myanmar: 'အဓိကလုပ်ငန်းအမျိုးအစား',
    };
    for (final language in AppLanguage.values) {
      final strings = AppLocalizations(language);
      expect(strings.mainOccupation, expectedMainOccupation[language]);
      expect(strings.saveOccupation, isNotEmpty);
      expect(strings.companyProfile, isNotEmpty);
      for (final occupation in Occupation.values) {
        expect(strings.occupation(occupation.legacyLabel), isNotEmpty);
      }
    }
  });
}
