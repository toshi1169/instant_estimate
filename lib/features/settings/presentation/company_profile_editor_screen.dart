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
      ),
    );
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
          TextButton(
            key: const Key('saveCompanyProfile'),
            onPressed: _save,
            child: Text(strings.text('保存')),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          key: const Key('companyProfileEditor'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Text(strings.companyProfileGuidance),
            const SizedBox(height: 16),
            _field(
              controller: _companyName,
              label: strings.companyNameOrTradeName,
              key: const Key('companyProfileCompanyName'),
              textInputAction: TextInputAction.next,
            ),
            _field(
              controller: _representativeName,
              label: strings.representativeName,
              key: const Key('companyProfileRepresentativeName'),
              textInputAction: TextInputAction.next,
            ),
            _field(
              controller: _postalCode,
              label: strings.postalCode,
              key: const Key('companyProfilePostalCode'),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
              ],
            ),
            _field(
              controller: _addressLine1,
              label: strings.addressLine1,
              key: const Key('companyProfileAddressLine1'),
              textInputAction: TextInputAction.next,
            ),
            _field(
              controller: _addressLine2,
              label: strings.addressLine2,
              key: const Key('companyProfileAddressLine2'),
              textInputAction: TextInputAction.next,
            ),
            _field(
              controller: _phoneNumber,
              label: strings.phoneNumber,
              key: const Key('companyProfilePhoneNumber'),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required Key key,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        key: key,
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
