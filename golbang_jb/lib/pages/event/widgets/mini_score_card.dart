/*
pages/event/widgets/mini_score_card.dart
사용자의 1~18홀까지의 점수를 표시하는 스코어카드
*/
import 'package:flutter/material.dart';

import '../../event/event_result_full_score_card.dart';

class MiniScoreCard extends StatelessWidget {
  final List<int> scorecard;
  final int eventId;

  const MiniScoreCard({super.key, 
    required this.scorecard,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    if (scorecard.isEmpty) {
      return _buildNoScorecardData(); // Display message when scorecard is empty
    }

    return Container(
      // margin: EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3), // 그림자의 위치를 조정
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Score",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(25.0),
            },
            border: TableBorder.all(color: Colors.transparent),
            children: [
              TableRow(
                children: [
                  const Center(
                    child: Text(
                      'H',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...List.generate(
                    9,
                        (index) => Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  const SizedBox.shrink(), // Left cell for spacing
                  ...scorecard.sublist(0, 9).map((score) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          score.toString(),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              TableRow(
                children: [
                  const Center(
                    child: Text(
                      'H',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...List.generate(
                    9,
                        (index) => Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${index + 10}',
                          style: const TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              TableRow(
                children: [
                  const SizedBox.shrink(), // Left cell for spacing
                  ...scorecard.sublist(9, 18).map((score) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          score.toString(),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton(
              onPressed: () {
                //TODO:전체 스코어카드 페이지로 이동하는 코드 추가 필요
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventResultFullScoreCard(
                      eventId: eventId,  // 현재 페이지에서 eventId를 전달
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[100], // 배경색 설정
                foregroundColor: Colors.green[800], // 글자색 설정
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text("전체 스코어카드 보기"),
            ),
          ),
        ],
      ),
    );
  }

  // A widget to show when there is no scorecard data
  Widget _buildNoScorecardData() {
    return const Center(
      child: Text(
        "Scorecard data is not available.",
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

}
