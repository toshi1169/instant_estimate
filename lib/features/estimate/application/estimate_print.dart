import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

typedef EstimatePdfBytesPrinter =
    Future<bool> Function({required Uint8List bytes, required String name});

typedef EstimatePdfLayout =
    Future<bool> Function({
      required LayoutCallback onLayout,
      required String name,
      required PdfPageFormat format,
      required bool dynamicLayout,
    });

/// 完成済みの正式PDF bytesを変更せず、OS標準の印刷UIへ渡す。
Future<bool> printEstimatePdfBytes({
  required Uint8List bytes,
  required String name,
  EstimatePdfLayout? layoutPdf,
}) {
  final performLayout = layoutPdf ?? _layoutPdf;
  return performLayout(
    name: name,
    format: PdfPageFormat.a4.landscape,
    dynamicLayout: false,
    onLayout: (_) async => bytes,
  );
}

Future<bool> _layoutPdf({
  required LayoutCallback onLayout,
  required String name,
  required PdfPageFormat format,
  required bool dynamicLayout,
}) => Printing.layoutPdf(
  name: name,
  format: format,
  dynamicLayout: dynamicLayout,
  onLayout: onLayout,
);
