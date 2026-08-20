enum CompanyProfileSection {
  companyName,
  representativeName,
  postalCode,
  addressLine1,
  addressLine2,
  phoneNumber,

  /// 旧JSONの住所ブロックを読み込むためだけに残す互換値。
  address,
}

const defaultCompanyProfileDisplayOrder = <CompanyProfileSection>[
  CompanyProfileSection.companyName,
  CompanyProfileSection.representativeName,
  CompanyProfileSection.postalCode,
  CompanyProfileSection.addressLine1,
  CompanyProfileSection.addressLine2,
  CompanyProfileSection.phoneNumber,
];

const defaultCompanyProfileExcelVisibleSections = <CompanyProfileSection>[
  CompanyProfileSection.companyName,
  CompanyProfileSection.representativeName,
  CompanyProfileSection.postalCode,
  CompanyProfileSection.addressLine1,
  CompanyProfileSection.addressLine2,
];

class CompanyProfile {
  const CompanyProfile({
    this.companyName = '',
    this.representativeName = '',
    this.postalCode = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.phoneNumber = '',
    this.displayOrder = defaultCompanyProfileDisplayOrder,
    this.excelVisibleSections = defaultCompanyProfileExcelVisibleSections,
  });

  final String companyName;
  final String representativeName;
  final String postalCode;
  final String addressLine1;
  final String addressLine2;
  final String phoneNumber;
  final List<CompanyProfileSection> displayOrder;
  final List<CompanyProfileSection> excelVisibleSections;

  List<CompanyProfileSection> get effectiveDisplayOrder =>
      _normalizeDisplayOrder(displayOrder);

  List<CompanyProfileSection> get effectiveExcelVisibleSections {
    final values = excelVisibleSections
        .expand(_expandLegacySection)
        .where(defaultCompanyProfileDisplayOrder.contains)
        .toSet()
        .take(5)
        .toList(growable: false);
    return values;
  }

  bool get isEmpty =>
      companyName.isEmpty &&
      representativeName.isEmpty &&
      postalCode.isEmpty &&
      addressLine1.isEmpty &&
      addressLine2.isEmpty &&
      phoneNumber.isEmpty;

  Map<String, Object> toJson() => <String, Object>{
    'companyName': companyName,
    'representativeName': representativeName,
    'postalCode': postalCode,
    'addressLine1': addressLine1,
    'addressLine2': addressLine2,
    'phoneNumber': phoneNumber,
    'displayOrder': effectiveDisplayOrder
        .map((section) => section.name)
        .toList(growable: false),
    'excelVisibleSections': effectiveExcelVisibleSections
        .map((section) => section.name)
        .toList(growable: false),
  };

  factory CompanyProfile.fromJson(Map<String, Object?> json) {
    String value(String key) => json[key] is String ? json[key]! as String : '';

    final restoredOrder = switch (json['displayOrder']) {
      final List<Object?> values =>
        values
            .whereType<String>()
            .map(
              (name) => CompanyProfileSection.values
                  .where((section) => section.name == name)
                  .firstOrNull,
            )
            .whereType<CompanyProfileSection>()
            .toSet()
            .toList(growable: false),
      _ => const <CompanyProfileSection>[],
    };
    final restoredExcelVisibility = switch (json['excelVisibleSections']) {
      final List<Object?> values =>
        values
            .whereType<String>()
            .map(
              (name) => CompanyProfileSection.values
                  .where((section) => section.name == name)
                  .firstOrNull,
            )
            .whereType<CompanyProfileSection>()
            .toList(growable: false),
      _ => null,
    };

    return CompanyProfile(
      companyName: value('companyName'),
      representativeName: value('representativeName'),
      postalCode: value('postalCode'),
      addressLine1: value('addressLine1'),
      addressLine2: value('addressLine2'),
      phoneNumber: value('phoneNumber'),
      displayOrder: _normalizeDisplayOrder(restoredOrder),
      excelVisibleSections:
          restoredExcelVisibility ?? defaultCompanyProfileExcelVisibleSections,
    );
  }
}

List<CompanyProfileSection> _normalizeDisplayOrder(
  Iterable<CompanyProfileSection> source,
) {
  final restored = source
      .expand(_expandLegacySection)
      .where(defaultCompanyProfileDisplayOrder.contains)
      .toSet()
      .toList(growable: true);
  return [
    ...restored,
    ...defaultCompanyProfileDisplayOrder.where(
      (section) => !restored.contains(section),
    ),
  ];
}

Iterable<CompanyProfileSection> _expandLegacySection(
  CompanyProfileSection section,
) sync* {
  if (section == CompanyProfileSection.address) {
    yield CompanyProfileSection.postalCode;
    yield CompanyProfileSection.addressLine1;
    yield CompanyProfileSection.addressLine2;
    return;
  }
  yield section;
}
