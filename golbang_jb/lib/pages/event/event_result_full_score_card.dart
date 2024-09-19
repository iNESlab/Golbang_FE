import 'package:flutter/material.dart';
import 'package:golbang/services/event_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repoisitory/secure_storage.dart'; // Riverpod 관련 패키지

class EventResultFullScoreCard extends ConsumerStatefulWidget {
  final int eventId;

  EventResultFullScoreCard({required this.eventId});

  @override
  _EventResultFullScoreCardState createState() => _EventResultFullScoreCardState();
}

class _EventResultFullScoreCardState extends ConsumerState<EventResultFullScoreCard> {
  List<dynamic> participants = [];
  Map<String, dynamic>? teamAScores;
  Map<String, dynamic>? teamBScores;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchScores();
    });
  }

  Future<void> fetchScores() async {
    final storage = ref.watch(secureStorageProvider);
    final eventService = EventService(storage);

    try {
      final response = await eventService.getScoreData(widget.eventId);
      if (response != null) {
        setState(() {
          participants = response['participants'];
          teamAScores = response['team_a_scores'];
          teamBScores = response['team_b_scores'];
          isLoading = false;
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
        title: Text('스코어카드'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            buildParticipantScoreTable(), // 참가자별 홀 점수 테이블
            buildScoreTable(), // 팀 점수와 참가자 점수 테이블
          ],
        ),
      ),
    );
  }

  // 팀 및 참가자 점수를 표시하는 테이블 위젯
  Widget buildScoreTable() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Table(
        border: TableBorder.all(),
        children: [
          // 헤더
          TableRow(
            children: [
              buildTableCell(' '),
              buildTableCell('전반전'),
              buildTableCell('후반전'),
              buildTableCell('전체 스코어'),
              buildTableCell('핸디캡 스코어'),
            ],
          ),
          // Team A Scores
          TableRow(
            children: [
              buildTableCell('Team A'),
              buildTableCell('${teamAScores?['front_nine_score'] ?? ''}'),
              buildTableCell('${teamAScores?['back_nine_score'] ?? ''}'),
              buildTableCell('${teamAScores?['total_score'] ?? ''}'),
              buildTableCell('${teamAScores?['handicap_score'] ?? ''}'),
            ],
          ),
          // Team B Scores
          TableRow(
            children: [
              buildTableCell('Team B'),
              buildTableCell('${teamBScores?['front_nine_score'] ?? ''}'),
              buildTableCell('${teamBScores?['back_nine_score'] ?? ''}'),
              buildTableCell('${teamBScores?['total_score'] ?? ''}'),
              buildTableCell('${teamBScores?['handicap_score'] ?? ''}'),
            ],
          ),
          // 참가자별 점수
          for (var participant in participants)
            TableRow(
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

  // 참가자들의 홀별 점수를 표시하는 테이블
  Widget buildParticipantScoreTable() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Table(
        border: TableBorder.all(),
        children: [
          // 테이블 헤더
          TableRow(
            children: [
              buildTableHeaderCell('홀'),
              for (var participant in participants)
                buildTableHeaderCell(participant['participant_name']),
            ],
          ),
          // 각 홀별 점수
          for (int hole = 1; hole <= 18; hole++) TableRow(
            children: [
              buildTableCell(hole.toString()), // 홀 번호
              for (var participant in participants)
                buildTableCell(
                    participant['scorecard'].length >= hole ? participant['scorecard'][hole - 1].toString() : '-'), // 각 참가자의 홀별 점수
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
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // 테이블 헤더 셀을 만드는 함수
  Widget buildTableHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
      child: Center(
        child: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}