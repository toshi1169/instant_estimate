import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  static const _keys = <String>[
    '…',
    '^',
    '⚙',
    '←',
    'a/b',
    '()',
    '%',
    '÷',
    '7',
    '8',
    '9',
    '×',
    '4',
    '5',
    '6',
    '−',
    '1',
    '2',
    '3',
    '+',
    '0',
    '00',
    '.',
    '=',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('計算履歴'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    '0',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                flex: 6,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _keys.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                    childAspectRatio: 1.42,
                  ),
                  itemBuilder: (context, index) {
                    final label = _keys[index];
                    final isAccent = const {
                      '^',
                      'a/b',
                      '()',
                      '%',
                      '÷',
                      '×',
                      '−',
                      '+',
                      '=',
                    }.contains(label);
                    return FilledButton(
                      onPressed: () {},
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: isDark
                            ? AppColors.darkKey
                            : AppColors.lightKey,
                        foregroundColor: isAccent
                            ? AppColors.accent
                            : Theme.of(context).colorScheme.onSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
