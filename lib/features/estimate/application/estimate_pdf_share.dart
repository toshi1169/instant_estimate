import 'dart:typed_data';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';

typedef EstimatePdfBytesSharer =
    Future<void> Function({
      required Uint8List bytes,
      required String fileName,
      required String subject,
      Rect? sharePositionOrigin,
    });

/// 完成済みの正式PDF bytesを変更せず、OS標準の保存・共有UIへ渡す。
Future<void> shareEstimatePdfBytes({
  required Uint8List bytes,
  required String fileName,
  required String subject,
  Rect? sharePositionOrigin,
}) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'application/pdf')],
      fileNameOverrides: [fileName],
      subject: subject,
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}
