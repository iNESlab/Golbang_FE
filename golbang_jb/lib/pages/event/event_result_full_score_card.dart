import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:golbang/services/event_service.dart';
import 'package:golbang/repoisitory/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Riverpod 관련 패키지

class EventResultFullScoreCard extends ConsumerStatefulWidget { // ConsumerStatefulWidget으로 변경
  final int eventId; // 이벤트 ID

  EventResultFullScoreCard({required this.eventId});

  @override
  _EventResultFullScoreCardState createState() => _EventResultFullScoreCardState();
}

class _EventResultFullScoreCardState extends ConsumerState<EventResultFullScoreCard> { // ConsumerState로 변경
  List<dynamic> participants = []; // 참가자 데이터를 저장할 리스트
  Map<String, dynamic>? teamAScores; // 팀 A 점수
  Map<String, dynamic>? teamBScores; // 팀 B 점수
  bool isLoading = true; // 로딩 상태 표시

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchScores(); // 페이지 로딩 시 점수 데이터를 불러옴
    });  }

  // EventService를 통해 API에서 점수 데이터를 가져오는 함수
  Future<void> fetchScores() async {
    // ref.watch를 사용하여 SecureStorage 인스턴스를 가져옴
    final storage = ref.watch(secureStorageProvider);
    final eventService = EventService(storage); // SecureStorage를 EventService에 전달

    try {
      final response = await eventService.getScoreData(widget.eventId); // EventService에서 getScoreData 호출
      if (response != null) {
        // API에서 받아온 데이터를 상태에 저장
        setState(() {
          participants = response['participants'];
          teamAScores = response['team_a_scores'];
          teamBScores = response['team_b_scores'];
          isLoading = false; // 로딩 완료
        });
      } else {
        print('Failed to load scores: response is null');
      }
    } catch (error) {
      print('Error fetching scores: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scorecard'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // 로딩 중일 때 로딩 표시
          : SingleChildScrollView(
        child: Column(
          children: [
            if (teamAScores != null && teamBScores != null) ...[
              buildTeamScoreTable('Team A', teamAScores!), // 팀 A 점수 테이블
              buildTeamScoreTable('Team B', teamBScores!), // 팀 B 점수 테이블
            ],
            buildParticipantTable(), // 참가자 점수 테이블
          ],
        ),
      ),
    );
  }

  // 팀 점수를 표시하는 테이블 위젯
  Widget buildTeamScoreTable(String teamName, Map<String, dynamic> teamScores) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Table(
        border: TableBorder.all(),
        children: [
          TableRow(
            children: [
              Text('$teamName Front 9'),
              Text('${teamScores['front_nine_score']}'),
            ],
          ),
          TableRow(
            children: [
              Text('$teamName Back 9'),
              Text('${teamScores['back_nine_score']}'),
            ],
          ),
          TableRow(
            children: [
              Text('$teamName Total Score'),
              Text('${teamScores['total_score']}'),
            ],
          ),
          TableRow(
            children: [
              Text('$teamName Handicap Score'),
              Text('${teamScores['handicap_score']}'),
            ],
          ),
        ],
      ),
    );
  }

  // 참가자 점수를 표시하는 테이블 위젯
  Widget buildParticipantTable() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Table(
        border: TableBorder.all(),
        children: [
          // 테이블 헤더
          TableRow(
            children: [
              buildTableCell('Participant'),
              buildTableCell('Front 9'),
              buildTableCell('Back 9'),
              buildTableCell('Total Score'),
              buildTableCell('Handicap Score'),
            ],
          ),
          // 참가자 데이터를 테이블에 추가
          for (var participant in participants) TableRow(
            children: [
              buildTableCell('${participant['participant_name']}'),
              buildTableCell('${participant['front_nine_score']}'),
              buildTableCell('${participant['back_nine_score']}'),
              buildTableCell('${participant['total_score']}'),
              buildTableCell('${participant['handicap_score']}'),
            ],
          ),
        ],
      ),
    );
  }

  // 테이블 셀을 만드는 함수
  Widget buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}
