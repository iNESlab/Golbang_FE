import 'package:flutter/material.dart';

class DayPickerField extends StatefulWidget {
  final TextEditingController controller;

  const DayPickerField({super.key, required this.controller});

  @override
  _DayPickerFieldState createState() => _DayPickerFieldState();
}

class _DayPickerFieldState extends State<DayPickerField> {
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1), // 기본값 (2000-01-01)
      firstDate: DateTime(1900), // 선택 가능한 최소 날짜
      lastDate: DateTime.now(), // 오늘까지 선택 가능
    );

    if (picked != null) {
      setState(() {
        widget.controller.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      readOnly: true, // 키보드 입력 비활성화
      onTap: () => _selectDate(context), // 클릭하면 달력 모달 열기
      decoration: InputDecoration(
        labelText: '생일 *',
        hintText: 'YYYY-MM-DD',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _selectDate(context), // 달력 아이콘 클릭 시에도 모달 열기
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '생일을 선택해주세요.';
        }
        return null;
      },
    );
  }
}
