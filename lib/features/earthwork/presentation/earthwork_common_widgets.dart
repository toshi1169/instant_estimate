import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/domain/transport_vehicle.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

double parseEarthworkNumber(String text) {
  return double.parse(text.trim().replaceAll(',', '.'));
}

double parseOptionalEarthworkNumber(String text) {
  return text.trim().isEmpty ? 0 : parseEarthworkNumber(text);
}

String formatEarthworkNumber(double value) {
  final text = value.toStringAsFixed(3);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}

String? validatePositiveEarthworkNumber(String? value) {
  final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
  if (number == null || !number.isFinite || number <= 0) {
    return '0より大きい数値を入力';
  }
  return null;
}

String? validateNonNegativeEarthworkNumber(String? value) {
  if ((value ?? '').trim().isEmpty) return null;
  final number = double.tryParse(value!.trim().replaceAll(',', '.'));
  if (number == null || !number.isFinite || number < 0) {
    return '0以上の数値を入力';
  }
  return null;
}

class EarthworkNumberField extends StatelessWidget {
  const EarthworkNumberField({
    required this.keyName,
    required this.controller,
    required this.label,
    required this.validator,
    this.suffix,
    this.helperText,
    super.key,
  });

  final String keyName;
  final TextEditingController controller;
  final String label;
  final String? suffix;
  final String? helperText;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: Key(keyName),
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        helperText: helperText,
      ),
      validator: validator,
    );
  }
}

class EarthworkResultCard extends StatelessWidget {
  const EarthworkResultCard({
    required this.label,
    required this.value,
    required this.onSend,
    this.note,
    super.key,
  });

  final String label;
  final String value;
  final String? note;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (note != null) ...[
                    const SizedBox(height: 2),
                    Text(note!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onSend,
              icon: const Icon(Icons.request_quote_outlined),
              label: Text(l10n.text('見積へ')),
            ),
          ],
        ),
      ),
    );
  }
}

class EarthworkReferenceNote extends StatelessWidget {
  const EarthworkReferenceNote({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        l10n.text(
          '※ 土量変化率・積載容量・法勾配等は、土質・車両・現場条件・設計条件等により異なります。表示値は初期値・参考値として扱い、実際の条件に合わせて変更してください。',
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class TransportVehicleFields extends StatelessWidget {
  const TransportVehicleFields({
    required this.vehicles,
    required this.selectedVehicleId,
    required this.capacityController,
    required this.onVehicleSelected,
    required this.onAddVehicle,
    required this.capacityKeyName,
    required this.vehicleKeyName,
    super.key,
  });

  final List<TransportVehicle> vehicles;
  final String selectedVehicleId;
  final TextEditingController capacityController;
  final ValueChanged<TransportVehicle> onVehicleSelected;
  final Future<TransportVehicle?> Function() onAddVehicle;
  final String capacityKeyName;
  final String vehicleKeyName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final standard = vehicles.where(
      (vehicle) => !vehicle.isCrawler && !vehicle.isCustom,
    );
    final crawlers = vehicles.where((vehicle) => vehicle.isCrawler);
    final customs = vehicles.where((vehicle) => vehicle.isCustom);
    return Column(
      children: [
        DropdownButtonFormField<String>(
          key: Key(vehicleKeyName),
          initialValue: selectedVehicleId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.text('運搬車両')),
          items: [
            _sectionItem(context, l10n.text('通常車両')),
            ...standard.map((vehicle) => _vehicleItem(vehicle, l10n)),
            _sectionItem(context, l10n.text('クローラータイプ')),
            ...crawlers.map((vehicle) => _vehicleItem(vehicle, l10n)),
            if (customs.isNotEmpty) ...[
              _sectionItem(context, l10n.text('ユーザー登録車両')),
              ...customs.map((vehicle) => _vehicleItem(vehicle, l10n)),
            ],
            DropdownMenuItem<String>(
              value: '_add_vehicle',
              child: Row(
                children: [
                  const Icon(Icons.add),
                  const SizedBox(width: 8),
                  Text(l10n.text('車両を追加')),
                ],
              ),
            ),
          ],
          onChanged: (id) async {
            if (id == null) return;
            if (id == '_add_vehicle') {
              final added = await onAddVehicle();
              if (added != null) onVehicleSelected(added);
              return;
            }
            onVehicleSelected(
              vehicles.firstWhere((vehicle) => vehicle.id == id),
            );
          },
        ),
        const SizedBox(height: 12),
        EarthworkNumberField(
          keyName: capacityKeyName,
          controller: capacityController,
          label: l10n.text('積載容量'),
          suffix: 'm³/回',
          helperText: l10n.text('※積載容量は車両・土質・積載条件により調整してください。'),
          validator: validatePositiveEarthworkNumber,
        ),
      ],
    );
  }

  DropdownMenuItem<String> _vehicleItem(
    TransportVehicle vehicle,
    AppLocalizations l10n,
  ) {
    final payload = vehicle.maximumPayloadTons == null
        ? ''
        : ' / ${formatEarthworkNumber(vehicle.maximumPayloadTons!)}t';
    return DropdownMenuItem<String>(
      value: vehicle.id,
      child: Text(
        '${vehicle.isCustom ? vehicle.name : l10n.text(vehicle.name)}  '
        '${formatEarthworkNumber(vehicle.initialCapacityCubicMeters)}m³$payload',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  DropdownMenuItem<String> _sectionItem(BuildContext context, String label) {
    return DropdownMenuItem<String>(
      enabled: false,
      value: '_section_$label',
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Future<TransportVehicle?> showAddTransportVehicleDialog(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context);
  final nameController = TextEditingController();
  final capacityController = TextEditingController();
  final weightController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final vehicle = await showDialog<TransportVehicle>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.text('車両を追加')),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('customVehicleName'),
                controller: nameController,
                decoration: InputDecoration(labelText: l10n.text('車両名')),
                textInputAction: TextInputAction.next,
                validator: (value) => (value ?? '').trim().isEmpty
                    ? l10n.text('車両名を入力してください')
                    : null,
              ),
              const SizedBox(height: 12),
              EarthworkNumberField(
                keyName: 'customVehicleCapacity',
                controller: capacityController,
                label: l10n.text('積載容量'),
                suffix: 'm³',
                validator: validatePositiveEarthworkNumber,
              ),
              const SizedBox(height: 12),
              EarthworkNumberField(
                keyName: 'customVehicleWeight',
                controller: weightController,
                label: l10n.text('最大積載重量'),
                suffix: 't',
                validator: validatePositiveEarthworkNumber,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.text('キャンセル')),
        ),
        FilledButton(
          key: const Key('saveCustomVehicle'),
          onPressed: () {
            if (!(formKey.currentState?.validate() ?? false)) return;
            final timestamp = DateTime.now().microsecondsSinceEpoch;
            final capacity = parseEarthworkNumber(capacityController.text);
            Navigator.of(dialogContext).pop(
              TransportVehicle(
                id: 'custom_$timestamp',
                name: nameController.text.trim(),
                initialCapacityCubicMeters: capacity,
                maximumPayloadTons: parseEarthworkNumber(weightController.text),
                approximateCapacityLabel:
                    '${formatEarthworkNumber(capacity)}m³',
                isCustom: true,
              ),
            );
          },
          child: Text(l10n.text('登録')),
        ),
      ],
    ),
  );
  nameController.dispose();
  capacityController.dispose();
  weightController.dispose();
  return vehicle;
}
