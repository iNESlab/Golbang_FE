import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/models/event.dart';
import 'package:golbang/pages/game/overall_score_page.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../models/hole_score.dart';
import '../../models/participant.dart';
import '../../models/profile/club_profile.dart';
import '../../models/socket/score_card.dart';
import '../../repoisitory/secure_storage.dart';

class ScoreCardPage extends ConsumerStatefulWidget {
  final Event event;

  const ScoreCardPage({
    super.key,
    required this.event,
  });

  @override
  _ScoreCardPageState createState() => _ScoreCardPageState();
}

class _ScoreCardPageState extends ConsumerState<ScoreCardPage> {
  int _currentPageIndex = 0;
  late final WebSocketChannel _channel;

  late final int _myParticipantId;
  late final List<Participant> _myGroupParticipants;
  final List<ScoreCard> _teamMembers = []; // ScoreCard 리스트
  final Map<int, List<HoleScore>> _scorecard = {}; // 참가자별 홀 점수
  // 입력 필드의 포커스를 감지하기 위한 FocusNode들을 저장하는 맵
  final Map<int, List<FocusNode>> _focusNodes = {};
  late final ClubProfile _clubProfile;

  @override
  initState() {
    super.initState();
    this._myParticipantId = widget.event.myParticipantId;
    this._myGroupParticipants = widget.event.participants.where((p)=>
        p.groupType==widget.event.memberGroup).toList();
    this._clubProfile = widget.event.club!;
    _initTeamMembers();
    _initWebSocket();
  }

  // myGroupParticipants를 이용한 초기화
  void _initTeamMembers() {
    List<HoleScore> initialScores = List.generate(18, (index) => HoleScore(holeNumber: index + 1, score: 0));

    for (var participant in _myGroupParticipants) {
      ScoreCard scoreCard = ScoreCard(
        participantId: participant.participantId,
        userName: participant.member?.name ?? 'Unknown',
        teamType: participant.teamType,
        groupType: participant.groupType,
        isGroupWin: false,
        isGroupWinHandicap: false,
        sumScore: participant.sumScore ?? 0,
        handicapScore: participant.handicapScore,
        scores: initialScores,
      );

      _teamMembers.add(scoreCard);
      _scorecard[participant.participantId] = List.from(initialScores);

      // 각 참가자별로 18개의 FocusNode를 생성하여 저장
      _focusNodes[participant.participantId] = List.generate(18, (_) => FocusNode());
    }
    setState(() {});
  }


  Future<void> _initWebSocket() async {
    SecureStorage secureStorage = ref.read(secureStorageProvider);
    final accessToken = await secureStorage.readAccessToken();
    // WebSocket 연결 설정
    _channel = IOWebSocketChannel.connect(
      Uri.parse('${dotenv.env['WS_HOST']}/participants/${_myParticipantId}/group/stroke'), // 실제 WebSocket 서버 주소로 변경
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
    _focusNodes.forEach((_, nodes) => nodes.forEach((node) => node.dispose()));
    _channel.sink.close(); // WebSocket 연결 종료
    super.dispose();
  }

  void _handleWebSocketData(String data) {
    // 데이터를 파싱
    var parsedData = jsonDecode(data);
    // 만약 데이터가 리스트 형식이면 처리
    if (parsedData is List) {
      for (var entry in parsedData) {
        ScoreCard scoreCard = _parseScoreCard(entry);

        setState(() {
          _updateTeamMember(scoreCard);
          _scorecard[scoreCard.participantId] = scoreCard.scores ?? [];
        });
      }
    }
    // 만약 데이터가 Map 형식이면 처리
    else print("Unexpected data format: response가 List가 아닙니다.");
  }

// ScoreCard 객체를 생성하는 함수
  ScoreCard _parseScoreCard(Map<String, dynamic> entry) {
    int participantId = int.parse(entry['participant_id'].toString());
    String userName = entry['user_name'] ?? 'Unknown';
    int groupType = int.parse(entry['group_type'].toString());
    String teamType = entry['team_type'];
    bool isGroupWin = entry['is_group_win'];
    bool isGroupWinHandicap = entry['is_group_win_handicap'];
    int sumScore = entry['sum_score'] ?? 0;
    int handicapScore = entry['handicap_score'] ?? 0;

    // scores를 HoleNumber 기준으로 정렬하고 누락된 홀 채우기
    List<HoleScore> scores = _parseScores(entry['scores']);

    return ScoreCard(
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
  }

  // 스코어 데이터를 정렬하고 누락된 홀 채우기
  List<HoleScore> _parseScores(List<dynamic> scoresJson) {
    List<HoleScore> scores = List.generate(18, (index) => HoleScore(holeNumber: index + 1, score: 0));

    for (var scoreData in scoresJson) {
      int holeNumber = scoreData['hole_number'];
      int score = scoreData['score'];
      scores[holeNumber - 1] = HoleScore(holeNumber: holeNumber, score: score);
    }

    return scores;
  }

  // 팀 멤버 정보를 업데이트하는 함수
  void _updateTeamMember(ScoreCard scoreCard) {
    int existingIndex = _teamMembers.indexWhere((sc) => sc.participantId == scoreCard.participantId);

    if (existingIndex != -1) {
      _teamMembers[existingIndex] = scoreCard;
    } else {
      _teamMembers.add(scoreCard);
    }
  }


  // WebSocket으로 점수를 전송하는 함수
  void _updateScore(int participantId, int holeNumber, int score) {
    final message = jsonEncode({
      'action': 'post',
      'participant_id': participantId,
      'hole_number': holeNumber,
      'score': score,
    });

    // WebSocket을 통해 전송
    _channel.sink.add(message);
    print('Score 전송: $message');
  }

  // 서버에 새로고침 요청을 보내는 함수
  Future<void> _handleRefresh() async {
    final message = jsonEncode({
      'action': 'get',
    });

    // WebSocket을 통해 새로고침 요청 전송
    _channel.sink.add(message);
    print('Score 전송: $message');

    // 약간의 지연시간을 추가하여 새로고침 완료 시각적으로 표시
    await Future.delayed(Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.event.eventTitle}', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton( // 뒤로 가기 버튼 추가
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
              icon: Icon(Icons.refresh),
              color: Colors.white,
              onPressed: _handleRefresh,
          )
        ],
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
          SizedBox(height: 8), // 거리 조정
          _buildSummaryTable(_teamMembers.map((m) => m.handicapScore).toList()), // 페이지 넘김 없이 고정된 스코어 요약 표
        ],
      ),
      backgroundColor: Colors.black,
    );
  }

  String _formattedDate(DateTime dateTime) {
    return dateTime.toIso8601String().split('T').first; // T 문자로 나누고 첫 번째 부분만 가져옴
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
              CircleAvatar(
                backgroundImage: _clubProfile.image.startsWith('http')
                    ? NetworkImage(_clubProfile.image)
                    : AssetImage(_clubProfile.image) as ImageProvider,
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${widget.event.club!.name}', style: TextStyle(color: Colors.white, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('${_formattedDate(widget.event.startDateTime)}', style: TextStyle(color: Colors.white, fontSize: 14)),
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
                      MaterialPageRoute(builder: (context) => OverallScorePage(event: widget.event)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                  ),
                  child: Text('전체 현황 조회'),
                ),
              ),
              // SizedBox(width: 8), TODO: mvp에서 일시적으로 제외
              // _buildRankIndicator('Rank', '2 고동범', Colors.red),
              // SizedBox(width: 8),
              // _buildRankIndicator('Handicap', '3 고동범', Colors.cyan),
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
          Text(title, style: TextStyle(color: Colors.white, fontSize: 12)),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 14)),
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
        // _buildTableHeaderCell('니어/롱기'),
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
        ..._teamMembers.map((ScoreCard member) {
          if (_scorecard[member.participantId] != null && holeIndex < _scorecard[member.participantId]!.length) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: TextFormField(
                  initialValue: _scorecard[member.participantId]![holeIndex].score.toString(),
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  focusNode: _focusNodes[member.participantId]?[holeIndex] ?? FocusNode(),
                  onChanged: (value) {
                    final score = int.tryParse(value) ?? 0;
                    _scorecard[member.participantId]![holeIndex] = HoleScore(
                      holeNumber: holeIndex,
                      score: score,
                    );
                  },
                  onFieldSubmitted: (value) {
                    final score = int.tryParse(value) ?? 0;
                    _updateScore(member.participantId, holeIndex + 1, score);
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4.0),
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  '-',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }
        }).toList(),
      ],
    );
  }

  Widget _buildSummaryTable(List<int> handiScores) {
    List<int> frontNine = _calculateScores(0,9);
    List<int> backNine = _calculateScores(9, 18);
    List<int> totalScores = List.generate(frontNine.length, (index) => frontNine[index] + backNine[index]);
    List<int> handicapScores = handiScores;

    return Container(
      color: Colors.black,
      padding: EdgeInsets.all(16.0),
      child: Table(
        border: TableBorder.all(color: Colors.grey),
        children: [
          _buildSummaryTableRow(['', ..._teamMembers.map((m) => m.userName ?? 'unknown').toList()]),
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

  List<int> _calculateScores(int start, int end) {
    return List.generate(_teamMembers.length, (i) {
      int participantId = _teamMembers[i].participantId;
      int sum = 0;

      // 참가자의 scorecard에서 앞 9개의 홀 점수를 더함
      for (int j = start; j < end; j++) {
        // 참가자의 _scorecard에 저장된 홀 점수에서 j번째 홀 점수를 가져와 더함
        if (_scorecard[participantId] != null && j < _scorecard[participantId]!.length) {
          sum += _scorecard[participantId]![j].score;
        }
      }
      return sum;
    });
  }

  Widget _buildPageIndicator() {
    return Padding(
      padding: const EdgeInsets.all(4.0), // 간격 조정
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