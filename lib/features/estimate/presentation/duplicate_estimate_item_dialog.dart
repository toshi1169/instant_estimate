import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../domain/estimate_item.dart';

enum DuplicateEstimateItemAction { addSeparately, updateExisting, cancel }

Future<DuplicateEstimateItemAction> showDuplicateEstimateItemDialog(
  BuildContext context,
  EstimateItem existing,
) async {
  final l10n = AppLocalizations.of(context);
  final name = existing.name.trim().isEmpty
      ? l10n.text('名称未入力')
      : existing.name.trim();
  return await showDialog<DuplicateEstimateItemAction>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.text('同じ計算内容があります')),
          content: Text(
            l10n.isEnglish
                ? '“$name” has already been added to the current estimate.'
                : '「$name」は、現在の見積にすでに追加されています。',
          ),
          actions: [
            TextButton(
              key: const Key('cancelDuplicateEstimateItem'),
              onPressed: () =>
                  Navigator.of(context).pop(DuplicateEstimateItemAction.cancel),
              child: Text(l10n.text('キャンセル')),
            ),
            TextButton(
              key: const Key('updateDuplicateEstimateItem'),
              onPressed: () => Navigator.of(
                context,
              ).pop(DuplicateEstimateItemAction.updateExisting),
              child: Text(l10n.text('既存明細を更新')),
            ),
            FilledButton(
              key: const Key('addDuplicateEstimateItemSeparately'),
              onPressed: () => Navigator.of(
                context,
              ).pop(DuplicateEstimateItemAction.addSeparately),
              child: Text(l10n.text('そのまま追加')),
            ),
          ],
        ),
      ) ??
      DuplicateEstimateItemAction.cancel;
}
