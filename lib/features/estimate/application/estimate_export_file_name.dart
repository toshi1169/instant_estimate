String safeEstimateExportBaseName(String value) {
  final sanitized = value
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_')
      .trim();
  return sanitized.isEmpty ? '見積書' : sanitized;
}

String formalEstimatePdfFileName(String estimateDisplayName) =>
    '${safeEstimateExportBaseName(estimateDisplayName)}_正式見積書.pdf';
