import 'package:flutter/services.dart';

class AllowNegativeNumbersFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    // 정규식을 사용하여 음수와 양수를 허용하는 조건 설정
    final isValid = RegExp(r'^-?\d*$').hasMatch(text);

    if (isValid) {
      return newValue;
    } else {
      return oldValue;
    }
  }
}
