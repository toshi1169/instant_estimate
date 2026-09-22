import 'dart:io';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';

typedef EstimateWorkbookFileSharer =
    Future<void> Function({
      required File file,
      required String subject,
      Rect? sharePositionOrigin,
    });

/// 完成済みの正式XLSXをOS標準の保存・共有UIへ渡す。
Future<void> shareEstimateWorkbookFile({
  required File file,
  required String subject,
  Rect? sharePositionOrigin,
}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile(
          file.path,
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      ],
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
