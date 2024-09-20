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
      backgroundColor: Colors.grey[200], // 배경색 설정
      appBar: AppBar(
        title: Text('스코어카드'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        scrollDirection: Axis.vertical, // 세로 스크롤
        child: Column(
          children: [
            buildParticipantDataTable(), // 참가자별 홀 점수 테이블
            buildScoreDataTable(), // 팀 점수 테이블
          ],
        ),
      ),
    );
  }

  // 팀 및 참가자 점수를 표시하는 DataTable 위젯
  Widget buildScoreDataTable() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // 가로 스크롤 설정
        child: Card(
          color: Colors.white, // 카드 배경 설정
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DataTable(
              columns: const [
                DataColumn(label: Text('팀/참가자')),
                DataColumn(label: Text('전반전')),
                DataColumn(label: Text('후반전')),
                DataColumn(label: Text('전체 스코어')),
                DataColumn(label: Text('핸디캡 스코어')),
              ],
              rows: [
                if (teamAScores != null) buildTeamDataRow('Team A', teamAScores), // teamAScores가 null이 아니면 표시
                if (teamBScores != null) buildTeamDataRow('Team B', teamBScores), // teamBScores가 null이 아니면 표시
                for (var participant in participants) buildParticipantDataRow(participant),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 팀 점수 행을 생성하는 함수
  DataRow buildTeamDataRow(String teamName, Map<String, dynamic>? teamScores) {
    return DataRow(
      cells: [
        DataCell(Text(teamName)),
        DataCell(Text('${teamScores?['front_nine_score'] ?? ''}')),
        DataCell(Text('${teamScores?['back_nine_score'] ?? ''}')),
        DataCell(Text('${teamScores?['total_score'] ?? ''}')),
        DataCell(Text('${teamScores?['handicap_score'] ?? ''}')),
      ],
    );
  }

  // 참가자 점수 행을 생성하는 함수
  DataRow buildParticipantDataRow(Map<String, dynamic> participant) {
    return DataRow(
      cells: [
        DataCell(Text(participant['participant_name'] ?? '')),
        DataCell(Text('${participant['front_nine_score']}')),
        DataCell(Text('${participant['back_nine_score']}')),
        DataCell(Text('${participant['total_score']}')),
        DataCell(Text('${participant['handicap_score']}')),
      ],
    );
  }

  // 참가자별 홀 점수를 표시하는 DataTable 위젯
  Widget buildParticipantDataTable() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // 가로 스크롤 설정
        child: Card(
          color: Colors.white, // 카드 배경 설정
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DataTable(
              columns: [
                const DataColumn(label: Text('홀')),
                for (var participant in participants)
                  DataColumn(label: Text(participant['participant_name'])),
              ],
              rows: [
                for (int hole = 1; hole <= 18; hole++)
                  DataRow(
                    cells: [
                      DataCell(Text(hole.toString())), // 홀 번호
                      for (var participant in participants)
                        DataCell(Text(
                          participant['scorecard'].length >= hole
                              ? participant['scorecard'][hole - 1].toString()
                              : '-',
                        )), // 각 참가자의 홀별 점수
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}