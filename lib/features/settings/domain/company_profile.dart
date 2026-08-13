class CompanyProfile {
  const CompanyProfile({
    this.companyName = '',
    this.representativeName = '',
    this.postalCode = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.phoneNumber = '',
  });

  final String companyName;
  final String representativeName;
  final String postalCode;
  final String addressLine1;
  final String addressLine2;
  final String phoneNumber;

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
  };

  factory CompanyProfile.fromJson(Map<String, Object?> json) {
    String value(String key) => json[key] is String ? json[key]! as String : '';

    return CompanyProfile(
      companyName: value('companyName'),
      representativeName: value('representativeName'),
      postalCode: value('postalCode'),
      addressLine1: value('addressLine1'),
      addressLine2: value('addressLine2'),
      phoneNumber: value('phoneNumber'),
    );
  }
}
