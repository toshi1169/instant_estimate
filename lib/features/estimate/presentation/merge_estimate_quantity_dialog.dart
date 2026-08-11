import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../domain/estimate_item.dart';
import '../domain/estimate_item_draft.dart';

enum MergeEstimateQuantityAction { merge, addSeparately, cancel }

Future<MergeEstimateQuantityAction> showMergeEstimateQuantityDialog(
  BuildContext context, {
  required EstimateItem existing,
  required EstimateItemDraft incoming,
}) async {
  final l10n = AppLocalizations.of(context);
  final name = existing.name.trim();
  final currentQuantity = _displayNumber(existing.quantity, l10n);
  final incomingQuantity = _displayNumber(incoming.quantity, l10n);
  final unit = existing.unit.trim();
  return await showDialog<MergeEstimateQuantityAction>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.text('既存明細へ数量を加算')),
          content: Text(
            l10n.choose(
              japanese:
                  '「$name」に数量を加算しますか？\n\n'
                  '既存：$currentQuantity $unit\n'
                  '今回：$incomingQuantity $unit',
              english:
                  'Add the quantity to “$name”?\n\n'
                  'Existing: $currentQuantity $unit\n'
                  'New: $incomingQuantity $unit',
              simplifiedChinese:
                  '要将数量加到“$name”吗？\n\n'
                  '现有：$currentQuantity $unit\n'
                  '本次：$incomingQuantity $unit',
            ),
          ),
          actions: [
            TextButton(
              key: const Key('cancelEstimateQuantityMerge'),
              onPressed: () =>
                  Navigator.of(context).pop(MergeEstimateQuantityAction.cancel),
              child: Text(l10n.text('キャンセル')),
            ),
            TextButton(
              key: const Key('mergeEstimateQuantities'),
              onPressed: () =>
                  Navigator.of(context).pop(MergeEstimateQuantityAction.merge),
              child: Text(l10n.text('既存明細へ加算')),
            ),
            FilledButton(
              key: const Key('addEstimateQuantitySeparately'),
              onPressed: () => Navigator.of(
                context,
              ).pop(MergeEstimateQuantityAction.addSeparately),
              child: Text(l10n.text('別明細として追加')),
            ),
          ],
        ),
      ) ??
      MergeEstimateQuantityAction.cancel;
}

String _displayNumber(double? value, AppLocalizations l10n) {
  if (value == null) return l10n.text('未入力');
  return value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}
