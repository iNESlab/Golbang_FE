/*
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
*/
import 'package:flutter/services.dart';

class AllowNegativeNumbersFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;

    // 정규식: '-'만 입력했을 때는 허용하지만, 최종 입력값은 숫자 포함해야 함
    final isValid = RegExp(r'^-?\d+$').hasMatch(text) || text == '-';

    if (text == "-") {
      return TextEditingValue(
        text: "-",
        selection: const TextSelection.collapsed(offset: 1),
      );
    }

    // "0"에서 "-" 입력 시 "0"을 삭제하고 "-" 유지
    if (oldValue.text == "0" && text == "-") {
      return const TextEditingValue(
        text: "-",
        selection: TextSelection.collapsed(offset: 1),
      );
    }

    // 백스페이스를 눌렀을 때 마지막 숫자가 남지 않고 완전히 삭제되도록 처리
    if (text.isEmpty) {
      return const TextEditingValue(
        text: "", // ✅ 완전히 빈 값으로 설정
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (isValid) {
      return newValue;
    } else {
      return oldValue;
    }
  }
}
