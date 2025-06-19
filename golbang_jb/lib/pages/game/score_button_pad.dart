// 점수 입력 취소
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScoreButtonPadStateful extends StatefulWidget {
  final int? selectedHole;
  final bool isEditing;
  // final bool isCompleted;
  final VoidCallback  onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onCancelScoreEdit;
  final void Function(int?) onScoreChanged;
  final int? tempScore;
  final double width;
  final double height;
  final double fontSizeLarge;
  final double fontSizeMedium;

  const ScoreButtonPadStateful({
    Key? key,
    required this.selectedHole,
    required this.isEditing,
    // required this.isCompleted,
    required this.onScoreChanged,
    required this.tempScore,
    required this.onComplete,
    required this.onEdit,
    required this.onCancelScoreEdit,
    required this.width,
    required this.height,
    required this.fontSizeLarge,
    required this.fontSizeMedium
  }) : super(key: key);

  @override
  State<ScoreButtonPadStateful> createState() => _ScoreButtonPadState();
}

class FutureVoidCallback {
}

class _ScoreButtonPadState extends State<ScoreButtonPadStateful> {
  int? _tempScore;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    setState(() {
      _tempScore = widget.tempScore;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEditing) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(widget.width * 0.02),
      color: Colors.grey[900],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 버튼 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 현재 선택된 점수 표시
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: widget.height * 0.01),
                  child: Text(
                    _tempScore != null ? _tempScore.toString() : '-',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.fontSizeLarge * 2,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // 확인/취소 버튼
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_tempScore != null) {
                        setState(() {
                          _tempScore = -_tempScore!;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tempScore != null && _tempScore! < 0
                          ? Colors.blue
                          : Colors.grey[800],
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.width * 0.04,
                        vertical: widget.height * 0.01,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '+/-',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.fontSizeMedium,
                      ),
                    ),
                  ),
                  SizedBox(width: widget.width * 0.02),
                  // 비우기 버튼
                  ElevatedButton(
                    onPressed: () => widget.onScoreChanged(null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.width * 0.04,
                        vertical: widget.height * 0.01,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete, color: Colors.white,
                            size: widget.fontSizeMedium),
                        const SizedBox(width: 4),
                        Text(
                          '비우기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.fontSizeMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: widget.height * 0.01),
          // 숫자 버튼들
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: widget.height * 0.01,
            crossAxisSpacing: widget.width * 0.02,
            childAspectRatio: 2.5,
            // 버튼 높이를 더 감소
            children: [
              // 1-9 숫자 버튼
              _buildNumberButton(1),
              _buildNumberButton(2),
              _buildNumberButton(3),
              _buildNumberButton(4),
              _buildNumberButton(5),
              _buildNumberButton(6),
              _buildNumberButton(7),
              _buildNumberButton(8),
              _buildNumberButton(9),
              // 빈 버튼 (왼쪽)
              ElevatedButton(
                onPressed: widget.onCancelScoreEdit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.width * 0.04,
                    vertical: widget.height * 0.01,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '취소',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // 0 버튼 (중앙)
              _buildNumberButton(0),
              // 빈 버튼 (오른쪽)
              ElevatedButton(
                onPressed: () {
                  widget.onScoreChanged(_tempScore);
                  widget.onComplete();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.width * 0.04,
                    vertical: widget.height * 0.01,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '확인',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: widget.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          int absValue = number;
          if (_tempScore != null && _tempScore! < 0) {
            // 음수 값을 유지
            _tempScore = -absValue;
          } else {
            _tempScore = absValue;
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _tempScore != null && number == _tempScore!.abs()
            ? Colors.blue
            : Colors.grey[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        number.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: widget.fontSizeMedium,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}