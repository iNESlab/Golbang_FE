import 'dart:io';
import 'package:flutter/material.dart';
import 'package:golbang/models/event.dart';
import 'package:golbang/pages/event/widgets/SummaryDataTable.dart';
import 'package:golbang/services/event_service.dart';
import 'package:excel/excel.dart' as xx; // excel 패키지 추가
import 'package:path_provider/path_provider.dart';  // path_provider 패키지 임포트
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart'; // 이메일 전송 패키지 추가
import '../../repoisitory/secure_storage.dart'; // Riverpod 관련 패키지
import 'package:flutter/services.dart'; // 화면 방향 변경을 위한 패키지


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
  Event? eventDetail;

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
      final temp_eventDetail = await eventService.getEventDetails(widget.eventId);
      if (response != null) {
        setState(() {
          participants = response['participants'];
          teamAScores = response['team_a_scores'];
          teamBScores = response['team_b_scores'];
          isLoading = false;
          eventDetail = temp_eventDetail;
        });
      } else {
        print('Failed to load scores: response is null');
      }
    } catch (error) {
      print('Error fetching scores: $error');
    }
  }
  Future<void> exportAndSendEmail() async {
    // 엑셀 파일 생성
    var excel = xx.Excel.createExcel();
    var sheet = excel['Sheet1'];

    // 열 제목 설정 (기본은 행 형태로)
    List<String> columnTitles = [
      '팀',
      '참가자',
      '전반전',
      '후반전',
      '전체 스코어',
      '핸디캡 스코어',
      'hole 1',
      'hole 2',
      'hole 3',
      'hole 4',
      'hole 5',
      'hole 6',
      'hole 7',
      'hole 8',
      'hole 9',
      'hole 10',
      'hole 11',
      'hole 12',
      'hole 13',
      'hole 14',
      'hole 15',
      'hole 16',
      'hole 17',
      'hole 18'
    ];

    // 팀 데이터와 참가자별 점수를 병합하여 정렬
    List<Map<String, dynamic>> sortedParticipants = [
      if (teamAScores != null)
        {
          'team': 'Team A',
          'participant_name': '-',
          'front_nine_score': teamAScores?['front_nine_score'],
          'back_nine_score': teamAScores?['back_nine_score'],
          'total_score': teamAScores?['total_score'],
          'handicap_score': '-',
          'scorecard': List.filled(18, '-'),
        },
      if (teamBScores != null)
        {
          'team': 'Team B',
          'participant_name': '-',
          'front_nine_score': teamBScores?['front_nine_score'],
          'back_nine_score': teamBScores?['back_nine_score'],
          'total_score': teamBScores?['total_score'],
          'handicap_score': '-',
          'scorecard': List.filled(18, '-'),
        },
      ...participants.map((participant) => {
        'team': participant['team'], // 팀 정보 추가
        'participant_name': participant['participant_name'],
        'front_nine_score': participant['front_nine_score'],
        'back_nine_score': participant['back_nine_score'],
        'total_score': participant['total_score'],
        'handicap_score': participant['handicap_score'],
        'scorecard': participant['scorecard'],
      }),
    ];

    // 팀 기준으로 정렬
    sortedParticipants.sort((a, b) => a['team'].compareTo(b['team']));

    // 데이터를 행 기준으로 변환
    List<List<dynamic>> rows = [
      columnTitles, // 제목
      ...sortedParticipants.map((participant) {
        return [
          participant['team'],
          participant['participant_name'],
          participant['front_nine_score'],
          participant['back_nine_score'],
          participant['total_score'],
          participant['handicap_score'],
          ...List.generate(18, (i) => participant['scorecard'].length > i ? participant['scorecard'][i] : '-'),
        ];
      }),
    ];

    // Transpose 적용 (행과 열 교환)
    List<List<dynamic>> transposedData = List.generate(
      rows[0].length,
          (colIndex) => rows.map((row) => row[colIndex]).toList(),
    );

    // 엑셀에 데이터 쓰기
    for (var row in transposedData) {
      sheet.appendRow(row);
    }

    // 외부 저장소 경로 가져오기
    Directory? directory;

    if (Platform.isAndroid) {
      // Android: 외부 저장소 경로 가져오기
      directory = await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      // iOS: 문서 디렉토리 가져오기
      directory = await getApplicationDocumentsDirectory();
    }
    if (directory != null) {
      String filePath = '${directory.path}/event_scores_${eventDetail?.eventId}.xlsx';
      File file = File(filePath);

      // 파일 쓰기
      await file.writeAsBytes(excel.encode()!);

      // 이메일 전송
      final Email email = Email(
        body: '제목: ${eventDetail?.eventTitle}\n 날짜: ${eventDetail?.startDateTime.toIso8601String().split('T').first}\n 장소: ${eventDetail?.site}',
        subject: '${eventDetail?.club!.name}_${eventDetail?.startDateTime.toIso8601String().split('T').first}_${eventDetail?.eventTitle}',
        recipients: [], // 받을 사람의 이메일 주소
        attachmentPaths: [filePath], // 첨부할 파일 경로
        isHTML: false,
      );

      try {
        await FlutterEmailSender.send(email);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일이 전송되었습니다.')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일 전송 실패: $error')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장 경로를 찾을 수 없습니다.')),
      );
    }
  }

  @override
  void dispose() {
    // 화면을 나갈 때 기본 상태로 회전 초기화
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, // 세로 모드
    ]);
    super.dispose();
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
            onPressed: exportAndSendEmail, // 이메일 전송 기능으로 변경
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            // 가로 모드에서 ParticipantDataTable 호출
            return buildParticipantDataTable();
          } else {
            // 세로 모드에서 ScoreTable 호출
            return buildScoreDataTable();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 화면을 항상 시계 방향으로 회전
          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
          if (isLandscape) {
            SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
          } else {
            SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
          }
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.screen_rotation, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // 오른쪽 아래에 배치
    );
  }

  Widget buildScoreDataTable() {
    // 공통 열 생성 함수
    List<DataColumn> createColumns(List<String> scoreTypes) {
      return [
        const DataColumn(label: Text('참가자')),
        ...scoreTypes.map((type) => DataColumn(label: Text(type))),
      ];
    }

    // 공통 행 생성 함수
    List<DataRow> createRows(List<String> scoreTypes, String Function(String, Map<String, dynamic>) scoreGetter) {
      return participants.map((participant) {
        return DataRow(
          cells: [
            DataCell(Text(participant['participant_name'])), // 참가자 이름
            ...scoreTypes.map((type) {
              final score = scoreGetter(type, participant);
              return DataCell(Text(score));
            }).toList(),
          ],
        );
      }).toList();
    }

    return LayoutBuilder(
      builder: (context, constraints) {

        return Column(
          children: [
            CustomDataTable(
              columns: createColumns(['전반전', '후반전']),
              rows: createRows(['전반전', '후반전'], (type, participant) {
                switch (type) {
                  case '전반전':
                    return participant['front_nine_score']?.toString() ?? '-';
                  case '후반전':
                    return participant['back_nine_score']?.toString() ?? '-';
                  default:
                    return '-';
                }
              }),
            ),
            CustomDataTable(
              columns: createColumns(['전체 스코어', '핸디캡 스코어']),
              rows: createRows(['전체 스코어', '핸디캡 스코어'], (type, participant) {
                switch (type) {
                  case '전체 스코어':
                    return participant['total_score']?.toString() ?? '-';
                  case '핸디캡 스코어':
                    return participant['handicap_score']?.toString() ?? '-';
                  default:
                    return '-';
                }
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "우측 회전 버튼을 눌러 전체 스코어를 확인하세요.",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            )

          ],
        );
      },
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

  // 참가자별 홀 점수를 표시하는 DataTable 위젯
  Widget buildParticipantDataTable() {
    // 참가자 데이터가 행, 홀이 열
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // 가로 스크롤 허용
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Card(
            color: Colors.white, // 카드 배경 설정
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('참가자')),
                  for (int hole = 1; hole <= 18; hole++)
                    DataColumn(label: Text('Hole $hole')), // 홀을 열로 표시
                ],
                rows: participants.map((participant) {
                  return DataRow(
                    cells: [
                      DataCell(Text(participant['participant_name'] ?? '-')), // 참가자 이름
                      for (int hole = 1; hole <= 18; hole++)
                        DataCell(Text(
                          participant['scorecard'].length >= hole
                              ? participant['scorecard'][hole - 1].toString()
                              : '-',
                        )), // 각 참가자의 홀별 점수
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        )
      ),
    );
  }

}
