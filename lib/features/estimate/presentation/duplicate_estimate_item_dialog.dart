import 'package:flutter/material.dart';

import '../domain/estimate_item.dart';

enum DuplicateEstimateItemAction { addSeparately, updateExisting, cancel }

Future<DuplicateEstimateItemAction> showDuplicateEstimateItemDialog(
  BuildContext context,
  EstimateItem existing,
) async {
  final name = existing.name.trim().isEmpty ? '名称未入力' : existing.name.trim();
  return await showDialog<DuplicateEstimateItemAction>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('同じ計算内容があります'),
          content: Text('「$name」は、現在の見積にすでに追加されています。'),
          actions: [
            TextButton(
              key: const Key('cancelDuplicateEstimateItem'),
              onPressed: () =>
                  Navigator.of(context).pop(DuplicateEstimateItemAction.cancel),
              child: const Text('キャンセル'),
            ),
            TextButton(
              key: const Key('updateDuplicateEstimateItem'),
              onPressed: () => Navigator.of(
                context,
              ).pop(DuplicateEstimateItemAction.updateExisting),
              child: const Text('既存明細を更新'),
            ),
            FilledButton(
              key: const Key('addDuplicateEstimateItemSeparately'),
              onPressed: () => Navigator.of(
                context,
              ).pop(DuplicateEstimateItemAction.addSeparately),
              child: const Text('そのまま追加'),
            ),
          ],
        ),
      ) ??
      DuplicateEstimateItemAction.cancel;
}
