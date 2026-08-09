import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_language.dart';

class AppLocalizations {
  const AppLocalizations(this.appLanguage);

  final AppLanguage appLanguage;

  bool get isEnglish => appLanguage == AppLanguage.english;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(AppLanguage.japanese);
  }

  String get appTitle => isEnglish ? 'Instant Estimate' : 'インスタント見積';
  String get language => isEnglish ? 'Language' : '言語';
  String get chooseLanguage => isEnglish ? 'Choose language' : '言語を選択';
  String get languageGuidance => isEnglish
      ? 'Select the language used in the app. You can change it later in Settings.'
      : 'アプリで使用する言語を選んでください。後から設定で変更できます。';
  String get continueLabel => isEnglish ? 'Continue' : '次へ';
  String get japanese => isEnglish ? 'Japanese' : '日本語';
  String get english => 'English';
  String get occupationTitle => isEnglish ? 'Choose occupation' : '業種を選択';
  String get occupationPrompt =>
      isEnglish ? 'Select your main occupation' : 'あなたの主な業種を選んでください';
  String get occupationGuidance => isEnglish
      ? 'This is used to prepare the initial calculators and estimate items. You can change it later in Settings.'
      : '表示する計算機能や見積項目の初期設定に使用します。後から設定で変更できます。';
  String get startWithOccupation =>
      isEnglish ? 'Start with this occupation' : 'この業種で始める';

  String occupation(String value) => switch (value) {
    '建築監督' => isEnglish ? 'Building supervisor' : value,
    '土木監督' => isEnglish ? 'Civil supervisor' : value,
    '建築基礎' => isEnglish ? 'Building foundations' : value,
    '外構' => isEnglish ? 'Exterior works' : value,
    '内装' => isEnglish ? 'Interior works' : value,
    '多能工' => isEnglish ? 'Multi-skilled worker' : value,
    _ => isEnglish ? 'Other' : value,
  };

  String get settings => isEnglish ? 'Settings' : '設定';
  String get help => isEnglish ? 'Help' : 'ヘルプ';
  String get adFreePlan =>
      isEnglish ? 'Ad-free (one-time purchase)' : '広告なし版（買い切り）';
  String get fullPlan => isEnglish ? 'Full plan (monthly)' : '完全版（月額）';
  String get convenientCalculations =>
      isEnglish ? 'Convenient calculations' : '便利計算一覧';
  String get unitConversion => isEnglish ? 'Unit conversion' : '単位変換';
  String get instantEstimate => isEnglish ? 'Instant estimate' : 'インスタント見積';
  String get unitPriceMaster => isEnglish ? 'Unit price master' : '単価マスタ';
  String get productivityMaster => isEnglish ? '歩掛：BUGAKARI' : '歩掛・生産性マスタ';
  String get productivityTermTitle => isEnglish ? '歩掛：BUGAKARI' : '歩掛';
  String get productivityTermExplanation => isEnglish
      ? 'Bugakari is a Japanese construction term for the labor required per unit of completed work. It is managed together with productivity records in this app.'
      : '歩掛は、施工数量1単位あたりに必要な人工や作業量を表す建設実務用語です。';
  String get adArea => isEnglish ? 'Ad area' : '広告エリア';

  String get displayAndCalculation =>
      isEnglish ? 'Display & calculation' : '表示・計算';
  String get theme => isEnglish ? 'Theme' : 'テーマ';
  String get systemTheme => isEnglish ? 'Follow device setting' : '端末に合わせる';
  String get whiteTheme => isEnglish ? 'White' : '白';
  String get grayTheme => isEnglish ? 'Gray' : 'グレー';
  String get blackTheme => isEnglish ? 'Black' : '黒';
  String get decimalPlaces => isEnglish ? 'Decimal places' : '小数点以下の表示桁数';
  String digits(int count) => isEnglish ? '$count places' : '$count桁';
  String get roundingMethod => isEnglish ? 'Rounding method' : '丸め方法';
  String get roundHalfUp => isEnglish ? 'Round half up' : '四捨五入';
  String get roundUp => isEnglish ? 'Round up' : '切上げ';
  String get roundDown => isEnglish ? 'Round down' : '切捨て';
  String get angleUnit => isEnglish ? 'Angle unit' : '角度単位';
  String get degrees => isEnglish ? 'Degrees (DEG)' : '度（DEG）';
  String get radians => isEnglish ? 'Radians (RAD)' : 'ラジアン（RAD）';
  String get calculationHistory => isEnglish ? 'Calculation history' : '計算履歴';
  String get ascendingHistory =>
      isEnglish ? 'Show history ascending' : '履歴を昇順で表示';
  String get ascendingOldest =>
      isEnglish ? 'Ascending (oldest first)' : '昇順（古い順）';
  String get descendingNewest =>
      isEnglish ? 'Descending (newest first)' : '降順（新しい順）';
  String get confirmHistoryDeletion =>
      isEnglish ? 'Confirm before deleting history' : '履歴削除時に確認する';
  String get clearAllHistory => isEnglish ? 'Delete all history' : '履歴をすべて削除';
  String get clearHistoryQuestion => isEnglish
      ? 'Delete all calculation history except starred entries?'
      : 'スター付き以外の計算履歴をすべて削除します。よろしいですか？';
  String get cancel => isEnglish ? 'Cancel' : 'キャンセル';
  String get delete => isEnglish ? 'Delete' : '削除';
  String get historyCleared =>
      isEnglish ? 'Calculation history was deleted' : '計算履歴をすべて削除しました';
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const {'ja', 'en'}.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    final language = locale.languageCode == 'en'
        ? AppLanguage.english
        : AppLanguage.japanese;
    return SynchronousFuture(AppLocalizations(language));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
