/*
pages/event/widgets/mini_score_card.dart
사용자의 1~18홀까지의 점수를 표시하는 스코어카드
*/
import 'package:flutter/material.dart';

class ScoreCard extends StatelessWidget {
  final List<int> scorecard;

  const ScoreCard({required this.scorecard});

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(),
      children: [
        TableRow(
          children: List.generate(18, (index) => Center(child: Text('Hole ${index + 1}'))),
        ),
        TableRow(
          children: scorecard
              .map((score) => Center(child: Text(score.toString())))
              .toList(),
        ),
      ],
    );
  }
}
