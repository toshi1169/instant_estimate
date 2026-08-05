import 'package:flutter/material.dart';

import '../domain/estimate_item.dart';
import '../domain/estimate_item_draft.dart';

enum MergeEstimateQuantityAction { merge, addSeparately, cancel }

Future<MergeEstimateQuantityAction> showMergeEstimateQuantityDialog(
  BuildContext context, {
  required EstimateItem existing,
  required EstimateItemDraft incoming,
}) async {
  final name = existing.name.trim();
  final currentQuantity = _displayNumber(existing.quantity);
  final incomingQuantity = _displayNumber(incoming.quantity);
  final unit = existing.unit.trim();
  return await showDialog<MergeEstimateQuantityAction>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('既存明細へ数量を加算'),
          content: Text(
            '「$name」に数量を加算しますか？\n\n'
            '既存：$currentQuantity $unit\n'
            '今回：$incomingQuantity $unit',
          ),
          actions: [
            TextButton(
              key: const Key('cancelEstimateQuantityMerge'),
              onPressed: () =>
                  Navigator.of(context).pop(MergeEstimateQuantityAction.cancel),
              child: const Text('キャンセル'),
            ),
            TextButton(
              key: const Key('mergeEstimateQuantities'),
              onPressed: () =>
                  Navigator.of(context).pop(MergeEstimateQuantityAction.merge),
              child: const Text('既存明細へ加算'),
            ),
            FilledButton(
              key: const Key('addEstimateQuantitySeparately'),
              onPressed: () => Navigator.of(
                context,
              ).pop(MergeEstimateQuantityAction.addSeparately),
              child: const Text('別明細として追加'),
            ),
          ],
        ),
      ) ??
      MergeEstimateQuantityAction.cancel;
}

String _displayNumber(double? value) {
  if (value == null) return '未入力';
  return value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}
