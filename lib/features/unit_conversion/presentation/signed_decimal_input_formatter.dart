import 'package:flutter/services.dart';

/// Accepts a signed decimal with optional three-digit grouping commas.
///
/// Empty text and a leading minus sign are kept as valid editing states.
class SignedDecimalInputFormatter extends TextInputFormatter {
  const SignedDecimalInputFormatter();

  static final RegExp _completeOrEditingValue = RegExp(
    r'^-$|^$|^-?(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d*)?$',
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _completeOrEditingValue.hasMatch(newValue.text)
        ? newValue
        : oldValue;
  }
}
