import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/core/localization/app_localizations.dart';
import 'package:instant_estimate/features/help/presentation/help_screen.dart';

void main() {
  testWidgets('簡体字中国語でヘルプ全体を表示できる', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('ja'), Locale('en'), Locale('zh', 'CN')],
        locale: Locale('zh', 'CN'),
        home: HelpScreen(),
      ),
    );

    expect(find.text('帮助'), findsOneWidget);
    expect(find.text('快速完成现场计算'), findsOneWidget);
    expect(find.text('计算器基本操作'), findsOneWidget);
    expect(find.text('分数输入与显示'), findsOneWidget);
    expect(find.text('计算历史'), findsOneWidget);
    expect(find.text('实用计算'), findsOneWidget);
    expect(find.text('即时估算'), findsOneWidget);
    expect(find.text('数据与使用注意事项'), findsOneWidget);
  });
}
