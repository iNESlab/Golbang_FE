/*
pages/event/widgets/mini_score_card.dart
사용자의 1~18홀까지의 점수를 표시하는 스코어카드
*/
import 'package:flutter/material.dart';

class MiniScoreCard extends StatelessWidget {
  final List<int> scorecard;

  const MiniScoreCard({required this.scorecard});

  @override
  Widget build(BuildContext context) {
    return Container(
      // margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // 그림자의 위치를 조정
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Score",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Table(
            columnWidths: {
              0: FixedColumnWidth(25.0),
            },
            border: TableBorder.all(color: Colors.transparent),
            children: [
              TableRow(
                children: [
                  Center(
                    child: Text(
                      'H',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...List.generate(
                    9,
                        (index) => Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  SizedBox.shrink(), // Left cell for spacing
                  ...scorecard.sublist(0, 9).map((score) {
                    return Center(
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          score.toString(),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
              TableRow(
                children: [
                  Center(
                    child: Text(
                      'H',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...List.generate(
                    9,
                        (index) => Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${index + 10}',
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  SizedBox.shrink(), // Left cell for spacing
                  ...scorecard.sublist(9, 18).map((score) {
                    return Center(
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          score.toString(),
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
          SizedBox(height: 10),
          Center(
            child: ElevatedButton(
              onPressed: () {
                // 전체 스코어카드 페이지로 이동하는 코드 추가 필요
              },
              child: Text("View Full Scorecard"),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
