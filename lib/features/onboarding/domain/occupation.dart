enum Occupation {
  buildingSupervisor('buildingSupervisor', '建築監督'),
  civilSupervisor('civilSupervisor', '土木監督'),
  foundation('foundation', '建築基礎'),
  exterior('exterior', '外構'),
  interior('interior', '内装'),
  multiTrade('multiTrade', '多能工'),
  other('other', 'その他');

  const Occupation(this.storageKey, this.legacyLabel);

  final String storageKey;
  final String legacyLabel;

  static Occupation? fromStoredValue(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final occupation in values) {
      if (value == occupation.storageKey || value == occupation.legacyLabel) {
        return occupation;
      }
    }
    return null;
  }
}
