import 'package:flutter/material.dart';

import '../../../core/domain/angle_unit.dart';
import '../../../core/theme/app_colors.dart';

class FunctionListDialog extends StatefulWidget {
  const FunctionListDialog({
    required this.angleUnit,
    required this.onAngleUnitChanged,
    super.key,
  });

  final AngleUnit angleUnit;
  final ValueChanged<AngleUnit> onAngleUnitChanged;

  static const functions = <String>[
    'π',
    'e',
    'φ',
    'log',
    'ln',
    'log₂',
    '√',
    '³√',
    '|x|',
    'x²',
    'x³',
    '1/x',
    'sin',
    'cos',
    'tan',
    'sin⁻¹',
    'cos⁻¹',
    'tan⁻¹',
    'sinh',
    'cosh',
    'tanh',
    'sinh⁻¹',
    'cosh⁻¹',
    'tanh⁻¹',
    '10ˣ',
    'eˣ',
    'x!',
  ];

  @override
  State<FunctionListDialog> createState() => _FunctionListDialogState();
}

class _FunctionListDialogState extends State<FunctionListDialog> {
  late AngleUnit _angleUnit = widget.angleUnit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      key: const Key('functionListDialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '関数一覧',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: GridView.builder(
                  key: const Key('functionListGrid'),
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                    mainAxisExtent: 48,
                  ),
                  itemCount: FunctionListDialog.functions.length,
                  itemBuilder: (context, index) {
                    final function = FunctionListDialog.functions[index];
                    return FilledButton(
                      key: Key('functionButton$index'),
                      onPressed: () => Navigator.of(context).pop(function),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: isDark
                            ? AppColors.darkKey
                            : AppColors.lightKey,
                        foregroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkKeyBorder
                                : AppColors.lightKeyBorder,
                          ),
                        ),
                      ),
                      child: Text(
                        function,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                key: const Key('functionAngleUnitSetting'),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '角度単位',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<AngleUnit>(
                        key: const Key('functionAngleUnitDropdown'),
                        value: _angleUnit,
                        items: const [
                          DropdownMenuItem(
                            value: AngleUnit.degrees,
                            child: Text('DEG（度）'),
                          ),
                          DropdownMenuItem(
                            value: AngleUnit.radians,
                            child: Text('RAD（ラジアン）'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null || value == _angleUnit) return;
                          setState(() => _angleUnit = value);
                          widget.onAngleUnitChanged(value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  key: const Key('cancelFunctionList'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
