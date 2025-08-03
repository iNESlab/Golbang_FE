/*
pages/event/widgets/mini_score_card.dart
사용자의 1~18홀까지의 점수를 표시하는 스코어카드
*/
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


class MiniScoreCard extends StatelessWidget {
  final List<int?> scorecard;
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
            "Scorecard",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(25.0),
              },
              border: TableBorder.all(
                color: Colors.black12,
                width: 1.5,
              ),
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.green[500], // row 전체의 배경색 설정
                  ),
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        width: double.infinity,
                        alignment: Alignment.center, // 텍스트를 중앙에 정렬
                        decoration: BoxDecoration(
                          color: Colors.green[800], // row 전체의 배경색 설정
                        ),
                        child: const Text(
                          'H',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    ...List.generate(
                      9,
                          (index) => Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [

                    Center(

                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        width: double.infinity,
                        alignment: Alignment.center, // 텍스트를 중앙에 정렬
                        decoration: const BoxDecoration(
                          color: Colors.black12, // row 전체의 배경색 설정
                        ),
                        child: const Text(
                          'S',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    ...scorecard.sublist(0, 9).map((score) {
                      final display = score != null ? score.toString() : '-';
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Text(
                            display,
                            style: const TextStyle(
                              fontSize: 14,
                              // TODO: Par를 기준으로 색을 다르게 하는 코드가 추후에 추가되면 좋을 것 같음. (color: score <= 3 ? Colors.blueAccent : score >= 5 ? Colors.red : Colors.black,)
                            ),
                          ),
                        )
                      );

                    }),
                  ],
                ),
                TableRow(
                  decoration: BoxDecoration(
                    color: Colors.green[500], // row 전체의 배경색 설정
                  ),
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        width: double.infinity,
                        alignment: Alignment.center, // 텍스트를 중앙에 정렬
                        decoration: BoxDecoration(
                          color: Colors.green[800], // row 전체의 배경색 설정
                        ),
                        child: const Text(
                          'H',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    ...List.generate(
                      9,
                          (index) => Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          // decoration: BoxDecoration(
                          //   color: Colors.white,
                          //   borderRadius: BorderRadius.circular(4),
                          // ),
                          child: Text(
                            '${index + 10}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        width: double.infinity,
                        alignment: Alignment.center, // 텍스트를 중앙에 정렬
                        decoration: const BoxDecoration(
                          color: Colors.black12, // row 전체의 배경색 설정
                        ),
                        child: const Text(
                          'S',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    ...scorecard.sublist(9, 18).map((score) {
                      final display = score != null ? score.toString() : '-';
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Text(
                            display,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          const Align(
              alignment: Alignment.centerLeft, // 왼쪽 정렬
              child: Text(
                '* H: Hole, S: Score',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              )
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton(
              onPressed: () {
                //TODO:전체 스코어카드 페이지로 이동하는 코드 추가 필요
                context.push('/events/$eventId/result', extra: {'isFull': true});
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
