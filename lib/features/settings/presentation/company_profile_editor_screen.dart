import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/app_localizations.dart';
import '../domain/company_profile.dart';

class CompanyProfileEditorScreen extends StatefulWidget {
  const CompanyProfileEditorScreen({required this.initialProfile, super.key});

  final CompanyProfile initialProfile;

  @override
  State<CompanyProfileEditorScreen> createState() =>
      _CompanyProfileEditorScreenState();
}

class _CompanyProfileEditorScreenState
    extends State<CompanyProfileEditorScreen> {
  late final _companyName = TextEditingController(
    text: widget.initialProfile.companyName,
  );
  late final _representativeName = TextEditingController(
    text: widget.initialProfile.representativeName,
  );
  late final _postalCode = TextEditingController(
    text: widget.initialProfile.postalCode,
  );
  late final _addressLine1 = TextEditingController(
    text: widget.initialProfile.addressLine1,
  );
  late final _addressLine2 = TextEditingController(
    text: widget.initialProfile.addressLine2,
  );
  late final _phoneNumber = TextEditingController(
    text: widget.initialProfile.phoneNumber,
  );
  late final List<CompanyProfileSection> _fieldOrder = [
    ...widget.initialProfile.effectiveDisplayOrder,
  ];
  late final Set<CompanyProfileSection> _excelVisibleSections = {
    ...widget.initialProfile.effectiveExcelVisibleSections,
  };
  var _settingsMode = false;

  @override
  void dispose() {
    _companyName.dispose();
    _representativeName.dispose();
    _postalCode.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _phoneNumber.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      CompanyProfile(
        companyName: _companyName.text.trim(),
        representativeName: _representativeName.text.trim(),
        postalCode: _postalCode.text.trim(),
        addressLine1: _addressLine1.text.trim(),
        addressLine2: _addressLine2.text.trim(),
        phoneNumber: _phoneNumber.text.trim(),
        displayOrder: List.unmodifiable(_fieldOrder),
        excelVisibleSections: List.unmodifiable(
          _fieldOrder.where(_excelVisibleSections.contains),
        ),
      ),
    );
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final section = _fieldOrder.removeAt(oldIndex);
      _fieldOrder.insert(newIndex, section);
    });
  }

  void _toggleExcelVisibility(
    CompanyProfileSection section,
    AppLocalizations strings,
  ) {
    if (_excelVisibleSections.contains(section)) {
      setState(() => _excelVisibleSections.remove(section));
      return;
    }
    if (_excelVisibleSections.length >= 5) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(strings.companyProfileExcelDisplayLimit)),
        );
      return;
    }
    setState(() => _excelVisibleSections.add(section));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.companyProfile),
        leading: IconButton(
          key: const Key('cancelCompanyProfile'),
          tooltip: strings.cancel,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
        actions: [
          IconButton(
            key: const Key('companyProfileSettingsMode'),
            tooltip: strings.companyProfileDisplaySettings,
            onPressed: () => setState(() => _settingsMode = !_settingsMode),
            icon: Icon(
              _settingsMode ? Icons.settings : Icons.settings_outlined,
            ),
          ),
          TextButton(
            key: const Key('saveCompanyProfile'),
            onPressed: _save,
            child: Text(strings.text('保存')),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(strings.companyProfileGuidance),
                  if (_settingsMode) ...[
                    const SizedBox(height: 8),
                    Text(
                      strings.companyProfileDisplaySettingsGuidance,
                      key: const Key('companyProfileSettingsGuidance'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                key: const Key('companyProfileEditor'),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                buildDefaultDragHandles: false,
                itemCount: _fieldOrder.length,
                onReorderItem: _settingsMode ? _reorder : (_, _) {},
                itemBuilder: (context, index) {
                  final section = _fieldOrder[index];
                  return _fieldRow(
                    section: section,
                    index: index,
                    strings: strings,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldRow({
    required CompanyProfileSection section,
    required int index,
    required AppLocalizations strings,
  }) {
    final field = _field(section, strings);
    return Padding(
      key: ValueKey('companyProfileField-${section.name}'),
      padding: const EdgeInsets.only(bottom: 14),
      child: _settingsMode
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ReorderableDragStartListener(
                  key: Key('companyProfileFieldHandle-${section.name}'),
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
                IconButton(
                  key: Key('companyProfileExcelVisibility-${section.name}'),
                  tooltip: _excelVisibleSections.contains(section)
                      ? strings.hideFromExcel
                      : strings.showInExcel,
                  onPressed: () => _toggleExcelVisibility(section, strings),
                  icon: Icon(
                    _excelVisibleSections.contains(section)
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(child: field),
              ],
            )
          : field,
    );
  }

  Widget _field(CompanyProfileSection section, AppLocalizations strings) {
    final (
      controller,
      label,
      key,
      keyboardType,
      action,
      inputFormatters,
    ) = switch (section) {
      CompanyProfileSection.companyName => (
        _companyName,
        strings.companyNameOrTradeName,
        const Key('companyProfileCompanyName'),
        TextInputType.text,
        TextInputAction.next,
        null,
      ),
      CompanyProfileSection.representativeName => (
        _representativeName,
        strings.representativeName,
        const Key('companyProfileRepresentativeName'),
        TextInputType.name,
        TextInputAction.next,
        null,
      ),
      CompanyProfileSection.postalCode => (
        _postalCode,
        strings.postalCode,
        const Key('companyProfilePostalCode'),
        TextInputType.text,
        TextInputAction.next,
        null,
      ),
      CompanyProfileSection.addressLine1 => (
        _addressLine1,
        strings.addressLine1,
        const Key('companyProfileAddressLine1'),
        TextInputType.streetAddress,
        TextInputAction.next,
        null,
      ),
      CompanyProfileSection.addressLine2 => (
        _addressLine2,
        strings.addressLine2,
        const Key('companyProfileAddressLine2'),
        TextInputType.streetAddress,
        TextInputAction.next,
        null,
      ),
      CompanyProfileSection.phoneNumber => (
        _phoneNumber,
        strings.phoneNumber,
        const Key('companyProfilePhoneNumber'),
        TextInputType.text,
        TextInputAction.done,
        <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-() ]')),
        ],
      ),
      CompanyProfileSection.address => throw StateError(
        'Legacy address section must be expanded before display.',
      ),
    };
    return TextField(
      key: key,
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: action,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
