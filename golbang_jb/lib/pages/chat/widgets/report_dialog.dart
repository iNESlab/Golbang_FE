import 'package:flutter/material.dart';

/// 신고 다이얼로그 위젯
/// 사용자가 메시지를 신고할 수 있는 다이얼로그입니다.
class ReportDialog extends StatefulWidget {
  final String userName;
  final double fontSizeLarge;
  final double fontSizeMedium;
  final double fontSizeSmall;
  final Function(String reason, String detail) onSubmit;

  const ReportDialog({
    super.key,
    required this.userName,
    required this.fontSizeLarge,
    required this.fontSizeMedium,
    required this.fontSizeSmall,
    required this.onSubmit,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final reportReasons = [
    '스팸 또는 광고',
    '욕설 또는 비하',
    '부적절한 내용',
    '개인정보 유출',
    '기타',
  ];

  String? selectedReason;
  final TextEditingController detailController = TextEditingController();

  @override
  void dispose() {
    detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('신고하기', style: TextStyle(fontSize: widget.fontSizeLarge)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('신고 대상: ${widget.userName}',
                 style: TextStyle(fontSize: widget.fontSizeMedium, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('신고 사유를 선택해주세요:',
                 style: TextStyle(fontSize: widget.fontSizeMedium)),
            const SizedBox(height: 8),
            ...reportReasons.map((reason) => RadioListTile<String>(
              title: Text(reason, style: TextStyle(fontSize: widget.fontSizeSmall)),
              value: reason,
              groupValue: selectedReason,
              onChanged: (value) => setState(() => selectedReason = value),
            )),
            const SizedBox(height: 16),
            TextField(
              controller: detailController,
              decoration: InputDecoration(
                labelText: '상세 내용 (선택사항)',
                border: OutlineInputBorder(),
                hintText: '신고 사유를 자세히 설명해주세요',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('취소', style: TextStyle(fontSize: widget.fontSizeMedium)),
        ),
        ElevatedButton(
          onPressed: selectedReason != null ? () {
            widget.onSubmit(selectedReason!, detailController.text);
            Navigator.of(context).pop();
          } : null,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('신고하기', style: TextStyle(fontSize: widget.fontSizeMedium, color: Colors.white)),
        ),
      ],
    );
  }
}

/// 신고 다이얼로그를 표시하는 헬퍼 함수
void showReportDialog({
  required BuildContext context,
  required String userName,
  required double fontSizeLarge,
  required double fontSizeMedium,
  required double fontSizeSmall,
  required Function(String reason, String detail) onSubmit,
}) {
  showDialog(
    context: context,
    builder: (context) => ReportDialog(
      userName: userName,
      fontSizeLarge: fontSizeLarge,
      fontSizeMedium: fontSizeMedium,
      fontSizeSmall: fontSizeSmall,
      onSubmit: onSubmit,
    ),
  );
}
