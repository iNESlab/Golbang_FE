import 'dart:io';
import 'package:flutter/material.dart';
import 'package:golbang/services/event_service.dart';
import 'package:excel/excel.dart'; // excel 패키지 추가
import 'package:path_provider/path_provider.dart';  // path_provider 패키지 임포트
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart'; // 이메일 전송 패키지 추가
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
        actions: [
          IconButton(
            icon: Icon(Icons.email), // 이메일 아이콘으로 변경
            onPressed: exportAndSendEmail,   // 이메일 전송 기능으로 변경
          ),
        ],
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

  Future<void> exportAndSendEmail() async {
    // 엑셀 파일 생성
    var excel = Excel.createExcel();
    var sheet = excel['Sheet1'];

    // excel.rename('Sheet1', 'Score Data');

    // 열 제목 설정
    List<String> columnTitles = ['팀/참가자', '전반전', '후반전', '전체 스코어', '핸디캡 스코어'];
    sheet.appendRow(columnTitles);

    // 팀 점수 추가
    if (teamAScores != null) {
      sheet.appendRow(['Team A', teamAScores?['front_nine_score'], teamAScores?['back_nine_score'], teamAScores?['total_score'], teamAScores?['handicap_score']]);
    }
    if (teamBScores != null) {
      sheet.appendRow(['Team B', teamBScores?['front_nine_score'], teamBScores?['back_nine_score'], teamBScores?['total_score'], teamBScores?['handicap_score']]);
    }

    // 참가자별 점수 추가
    for (var participant in participants) {
      sheet.appendRow([
        participant['participant_name'],
        participant['front_nine_score'],
        participant['back_nine_score'],
        participant['total_score'],
        participant['handicap_score']
      ]);
    }

    // 외부 저장소 경로 가져오기
    Directory? directory = await getExternalStorageDirectory();
    if (directory != null) {
      String filePath = '${directory.path}/event_scores.xlsx';
      File file = File(filePath);

      // 파일 쓰기
      await file.writeAsBytes(excel.encode()!);

      // 이메일 전송
      final Email email = Email(
        body: '이메일 본문 내용을 여기에 작성하세요.',
        subject: '이벤트 스코어 엑셀 파일',
        recipients: [],  // 받을 사람의 이메일 주소
        attachmentPaths: [filePath],  // 첨부할 파일 경로
        isHTML: false,
      );

      try {
        await FlutterEmailSender.send(email);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일이 전송되었습니다.')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일 전송 실패: $error')),
        );
      }

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 경로를 찾을 수 없습니다.')),
      );
    }
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
