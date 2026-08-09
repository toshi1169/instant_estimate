import 'package:flutter/material.dart';

class TechnicalTermInfo extends StatelessWidget {
  const TechnicalTermInfo({
    required this.title,
    required this.explanation,
    super.key,
  });

  final String title;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: Key('technicalTermInfo-$title'),
      tooltip: title,
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.info_outline, size: 19),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(explanation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }
}
