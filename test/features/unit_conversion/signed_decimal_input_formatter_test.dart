import 'package:flutter_test/flutter_test.dart';
import 'package:instant_estimate/features/unit_conversion/presentation/signed_decimal_input_formatter.dart';

void main() {
  const formatter = SignedDecimalInputFormatter();

  TextEditingValue apply(String oldText, String newText) {
    return formatter.formatEditUpdate(
      TextEditingValue(text: oldText),
      TextEditingValue(text: newText),
    );
  }

  test('正負の整数・小数と入力途中状態を許可する', () {
    for (final value in const [
      '',
      '-',
      '123',
      '12.3',
      '12.',
      '-12',
      '-12.3',
      '-12.',
    ]) {
      expect(apply('', value).text, value, reason: '$value の許可状態が正しくありません');
    }
  });

  test('正しい3桁区切りカンマを許可する', () {
    for (final value in const [
      '1,234',
      '1,234.5',
      '-1,234.5',
      '12,345,678.90',
    ]) {
      expect(apply('', value).text, value);
    }
  });

  test('文字・複数記号・不正位置の符号を拒否して旧値を保つ', () {
    for (final value in const [
      'abc',
      '--1',
      '1-2',
      '1.2.3',
      '+1',
      '1+2',
      '-+1',
    ]) {
      expect(apply('12', value).text, '12', reason: '$value を拒否できません');
    }
  });

  test('不正な位置・桁数のカンマを拒否して旧値を保つ', () {
    for (final value in const [
      ',123',
      '123,',
      '1,23',
      '12,34',
      '1234,567',
      '1,234,56',
      '1,,234',
      '1,234.5,6',
    ]) {
      expect(apply('12', value).text, '12', reason: '$value を拒否できません');
    }
  });
}
