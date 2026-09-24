import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';

class EstimatePdfScriptNotice extends StatelessWidget {
  const EstimatePdfScriptNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final notice = AppLocalizations.of(context).formalPdfScriptSupportNotice;
    if (notice == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              notice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
