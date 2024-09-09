import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/pages/game/overall_score_page.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../models/hole_score.dart';
import '../../models/participant.dart';
import '../../models/socket/score_card.dart';
import '../../repoisitory/secure_storage.dart';

class ScoreCardPage extends ConsumerStatefulWidget {
  final int participantId;
  final List<Participant> myGroupParticipants;

  const ScoreCardPage( {
    super.key,
    required this.participantId,
    required this.myGroupParticipants,
  });

  @override
  _ScoreCardPageState createState() => _ScoreCardPageState();
}

class _ScoreCardPageState extends ConsumerState<ScoreCardPage> {

  int _currentPageIndex = 0;
  /*
  final List<String> _teamMembers = ['고동범', '김민정', '박재윤', '정수미'];
  final List<List<String>> _scores = List.generate(18, (_) => List.generate(4, (_) => ''));
  final List<int> _handicaps = [2, 3, 1, 4]; // 각 선수의 핸디캡 설정
   */

  late final WebSocketChannel _channel;

  final List<ScoreCard> _teamMembers = []; // ScoreCard 리스트
  final Map<int, List<HoleScore>> _scorecard = {}; // 참가자별 홀 점수

  @override
  initState() {
    super.initState();
    _initWebSocket();
  }

  Future<void> _initWebSocket() async {
    SecureStorage secureStorage = ref.read(secureStorageProvider);
    final accessToken = await secureStorage.readAccessToken();
    print('websocket: accessToken: $accessToken');
    // WebSocket 연결 설정
    _channel = IOWebSocketChannel.connect(
      Uri.parse('${dotenv.env['WS_HOST']}/participants/${widget.participantId}/group/stroke'), // 실제 WebSocket 서버 주소로 변경
      headers: {
        'Authorization': 'Bearer $accessToken', // 토큰을 헤더에 포함
      },
    );

    // WebSocket 메시지를 수신
    _channel.stream.listen((data) {
      print('WebSocket 데이터 수신: $data'); // 수신된 데이터를 로그로 출력
      _handleWebSocketData(data);
    }, onError: (error) {
      print('WebSocket 오류 발생: $error'); // 오류 발생 시 로그 출력
    }, onDone: () {
      print('WebSocket 연결 종료'); // 연결이 종료되면 로그 출력
    });
  }

  @override
  void dispose() {
    _channel.sink.close(); // WebSocket 연결 종료
    super.dispose();
  }

  void _handleWebSocketData(String data) {
    // WebSocket에서 수신한 JSON 데이터를 파싱하여 ScoreCard 갱신
    List<dynamic> parsedData = jsonDecode(data);
    print('WebSocket 데이터 파싱 완료: $parsedData'); // 파싱된 데이터를 로그로 출력

    for (var entry in parsedData) {
      int participantId = int.parse(entry['participant_id']);
      String userName = entry['user_name'] ?? 'Unknown';
      int groupType = int.parse(entry['group_type']);
      String teamType = entry['team_type'];
      bool isGroupWin = entry['is_group_win'];
      bool isGroupWinHandicap = entry['is_group_win_handicap'];
      int sumScore = entry['sum_score'] ?? 0;
      int handicapScore = entry['handicap_score'] ?? 0;
      List<dynamic> scoresJson = entry['scores'];

      // 홀 점수 데이터를 HoleScore 리스트로 변환
      List<HoleScore> scores = scoresJson.map((scoreData) {
        return HoleScore(
          holeNumber: scoreData['hole_number'],
          score: scoreData['score'],
        );
      }).toList();

      print('ScoreCard 생성: participantId: $participantId, userName: $userName'); // ScoreCard 생성 로그 출력

      // ScoreCard 생성
      ScoreCard scoreCard = ScoreCard(
        participantId: participantId,
        userName: userName,
        teamType: teamType,
        groupType: groupType,
        isGroupWin: isGroupWin,
        isGroupWinHandicap: isGroupWinHandicap,
        sumScore: sumScore,
        handicapScore: handicapScore,
        scores: scores,
      );

      // 기존 팀원 정보 갱신 또는 새로운 팀원 추가
      setState(() {
        int existingIndex =
        _teamMembers.indexWhere((sc) => sc.participantId == participantId);

        if (existingIndex != -1) {
          _teamMembers[existingIndex] = scoreCard;
        } else {
          _teamMembers.add(scoreCard);
        }

        _scorecard[participantId] = scores;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('제 18회 iNES 골프대전',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton( // 뒤로 가기 버튼 추가
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                    },
                    children: [
                      _buildScoreTable(1, 9),
                      _buildScoreTable(10, 18),
                    ],
                  ),
                ),
                _buildPageIndicator(),
              ],
            ),
          ),
          SizedBox(height: 8),  // 거리 조정
          _buildSummaryTable(_teamMembers.map((m)=>m.handicapScore).toList()), // 페이지 넘김 없이 고정된 스코어 요약 표
        ],
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/images/google.png', // assets에 있는 로고 이미지 사용
                height: 40,
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '제 18회 iNES 골프대전',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '2024.03.18',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OverallScorePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                  ),
                  child: Text('전체 현황 조회'),
                ),
              ),
              SizedBox(width: 8),
              _buildRankIndicator('Rank', '2 고동범', Colors.red),
              SizedBox(width: 8),
              _buildRankIndicator('Handicap', '3 고동범', Colors.cyan),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankIndicator(String title, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTable(int startHole, int endHole) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.black,
        padding: EdgeInsets.all(16.0),
        child: Table(
          border: TableBorder.all(color: Colors.grey),
          children: [
            _buildTableHeaderRow(),
            for (int i = startHole; i <= endHole; i++)
              _buildEditableTableRow(i - 1),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableHeaderRow() {
    return TableRow(
      children: [
        _buildTableHeaderCell('홀'),
        for (ScoreCard member in _teamMembers) _buildTableHeaderCell(member.userName ?? 'Unknown'),
        _buildTableHeaderCell('니어/롱기'),
      ],
    );
  }

  Widget _buildTableHeaderCell(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
      child: Center(
        child: Text(
          title,
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  TableRow _buildEditableTableRow(int holeIndex) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Text(
              (holeIndex + 1).toString(),
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        // 팀원별 점수 열 추가
        for (ScoreCard member in _teamMembers)
          if (_scorecard[member.participantId] != null &&
              holeIndex < _scorecard[member.participantId]!.length)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  _scorecard[member.participantId]![holeIndex].score.toString(),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          else
          // 점수가 없을 경우 대체 텍스트
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  '-',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 2.0),
          child: Center(
            child: TextFormField(
              initialValue: '', // 초기 값 설정
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly], // 숫자만 입력 가능하도록 설정
              onChanged: (value) {
                // 필요한 경우 입력값을 처리할 수 있도록 설정
              },
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4.0),
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTable(List<int> handiScores) {
    List<int> frontNine = _calculateFrontNineScores();
    List<int> backNine = _calculateBackNineScores();
    List<int> totalScores = _calculateTotalScores();
    List<int> handicapScores = handiScores;
    return Container(
      color: Colors.black,
      padding: EdgeInsets.all(16.0),
      child: Table(
        border: TableBorder.all(color: Colors.grey),
        children: [
          _buildSummaryTableRow(['', ..._teamMembers.map((m) => m.userName??'unknown').toList()]),
          _buildSummaryTableRow(['전반', ...frontNine.map((e) => e.toString()).toList()]),
          _buildSummaryTableRow(['후반', ...backNine.map((e) => e.toString()).toList()]),
          _buildSummaryTableRow(['스코어', ...totalScores.map((e) => e.toString()).toList()]),
          _buildSummaryTableRow(['핸디 스코어', ...handicapScores.map((e) => e.toString()).toList()]),
        ],
      ),
    );
  }

  TableRow _buildSummaryTableRow(List<String> cells) {
    return TableRow(
      children: cells.map((cell) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0), // 간격 조정
          child: Center(
            child: Text(
              cell,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        );
      }).toList(),
    );
  }

  List<int> _calculateFrontNineScores() {
    return List.generate(_teamMembers.length, (i) {
      int participantId = _teamMembers[i].participantId;
      int sum = 0;

      // 참가자의 scorecard에서 앞 9개의 홀 점수를 더함
      for (int j = 0; j < 9; j++) {
        // 참가자의 _scorecard에 저장된 홀 점수에서 j번째 홀 점수를 가져와 더함
        if (_scorecard[participantId] != null && j < _scorecard[participantId]!.length) {
          sum += _scorecard[participantId]![j].score;
        }
      }
      return sum;
    });
  }
  List<int> _calculateBackNineScores() {
    return List.generate(_teamMembers.length, (i) {
      int participantId = _teamMembers[i].participantId;
      int sum = 0;

      // 참가자의 scorecard에서 앞 9개의 홀 점수를 더함
      for (int j = 9; j < 18; j++) {
        // 참가자의 _scorecard에 저장된 홀 점수에서 j번째 홀 점수를 가져와 더함
        if (_scorecard[participantId] != null && j < _scorecard[participantId]!.length) {
          sum += _scorecard[participantId]![j].score;
        }
      }

      return sum;
    });
  }

  List<int> _calculateTotalScores() {
    return List.generate(_teamMembers.length, (i) {
      return _calculateFrontNineScores()[i] + _calculateBackNineScores()[i];
    });
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.all(4.0),  // 간격 조정
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIndicatorDot(0),
          SizedBox(width: 8),
          _buildIndicatorDot(1),
        ],
      ),
    );
  }

  Widget _buildIndicatorDot(int index) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPageIndex == index ? Colors.white : Colors.grey,
      ),
    );
  }
}