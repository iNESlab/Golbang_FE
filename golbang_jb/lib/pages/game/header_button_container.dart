
// 헤더 버튼 전용 StatefulWidget
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HeaderButtonContainer extends StatefulWidget {
  final int? selectedHole;
  final bool isEditing;
  // final bool isCompleted;
  final bool allScoresEntered;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final double fontSize;

  const HeaderButtonContainer({
    Key? key,
    required this.selectedHole,
    required this.isEditing,
    // required this.isCompleted,
    required this.allScoresEntered,
    required this.onComplete,
    required this.onEdit,
    required this.fontSize,
  }) : super(key: key);

  @override
  State<HeaderButtonContainer> createState() => _HeaderButtonContainerState();
}

class _HeaderButtonContainerState extends State<HeaderButtonContainer> {
  @override
  Widget build(BuildContext context) {
    // 수정 중인 경우에도 전체 현황 조회 버튼 표시
    if (widget.isEditing) {
      log('편집 중 -> 전체 현황 조회 버튼 표시');
      return const SizedBox.shrink();
    }

    return const SizedBox.shrink();

    // 선택된 홀이 없으면 전체 현황 조회 버튼만 표시
    // if (widget.selectedHole == null) {
    //   log('홀 선택 안됨 -> 전체 현황 조회 버튼 표시');
    //   return const SizedBox.shrink();
    // }

    // log('헤더 버튼 렌더링: selectedHole=${widget.selectedHole}, isEditing=${widget.isEditing}');

    // 선택된 홀이 있고 그 홀이 완료된 상태인 경우 빈 공간 표시
    // if (widget.isCompleted) {
    //   log('완료된 홀 선택됨 -> 빈 공간 표시');
    //   return const SizedBox.shrink();
    // }

    // 홀 완료 버튼 표시 (모든 점수가 입력된 경우에만 활성화)
    log('일반 홀 선택됨 -> 홀 완료 버튼 표시(활성화: ${widget.allScoresEntered})');
    // return ElevatedButton(
    //   onPressed: widget.allScoresEntered ? widget.onComplete : null,
    //   style: ElevatedButton.styleFrom(
    //     backgroundColor: Colors.green,
    //     disabledBackgroundColor: Colors.green.withOpacity(0.3),
    //     disabledForegroundColor: Colors.white.withOpacity(0.5),
    //   ),
    //   child: Row(
    //     mainAxisAlignment: MainAxisAlignment.center,
    //     children: [
    //       Icon(Icons.check, color: widget.allScoresEntered ? Colors.white : Colors.white.withOpacity(0.5)),
    //       const SizedBox(width: 8),
    //       Text(
    //           '홀 완료',
    //           style: TextStyle(
    //               color: widget.allScoresEntered ? Colors.white : Colors.white.withOpacity(0.5),
    //               fontSize: widget.fontSize
    //           )
    //       ),
    //     ],
    //   ),
    // );
  }
}