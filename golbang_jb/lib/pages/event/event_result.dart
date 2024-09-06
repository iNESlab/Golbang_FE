/*
pages/event/event_result.dart
이벤트 전체 결과 조회 페이지
 */
import 'package:flutter/material.dart';
import 'package:golbang/pages/event/widgets/event_header.dart';
import 'package:golbang/pages/event/widgets/mini_score_card.dart';
import 'package:golbang/pages/event/widgets/ranking_list.dart';

class EventResultPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("이벤트 전체 결과"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventHeader(
              eventTitle: "제 18회 iNES 골프대전",
              location: "성남시 골프장",
              startDateTime: DateTime.now(),
              endDateTime: DateTime.now().add(Duration(hours: 4)),
              gameMode: "스트로크, 팀전",
              participantCount: "20",  // 예시로 참가자 수
              myGroupType: "A",         // 예시로 그룹 타입
            ),
            SizedBox(height: 20),
            // UserProfile 등 나머지 요소들도 필요시 추가
            Text("Score Card", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ScoreCard(
              scorecard: List.generate(18, (index) => index + 4),
            ),
            SizedBox(height: 20),
            Text("Ranking", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            RankingList(
              participants: [
                {'rank': '1', 'name': '김민정', 'stroke': '78'},
                {'rank': '2', 'name': '윤성문', 'stroke': '82'},
                {'rank': '3', 'name': '고중범', 'stroke': '85'},
              ],
            ),
          ],
        ),
      ),
    );
  }
}
