import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/models/event.dart';
import 'package:golbang/pages/game/overall_score_page.dart';
import 'package:golbang/utils/AllowNavigateNumbersFormatter.dart';
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
  late final Map<int, String> _participantNames; // participantId를 키로 하는 맵

  late final int _myParticipantId;
  late final List<Participant> _myGroupParticipants;
  final List<ScoreCard> _teamMembers = []; // ScoreCard 리스트
  final Map<int, List<HoleScore>> _scorecard = {}; // 참가자별 홀 점수
  // 입력 필드의 포커스를 감지하기 위한 FocusNode들을 저장하는 맵
  final Map<int, List<FocusNode>> _focusNodes = {};
  late final ClubProfile _clubProfile;
  final Map<int, List<TextEditingController>> _controllers = {}; // TextEditingController를 참가자별로 관리

  late double width;
  late double height;
  late double fontSizeLarge;
  late double fontSizeSmall;
  late double avatarSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.of(context).size; // 화면 크기 가져오기
    width = size.width;
    height = size.height;
    fontSizeLarge = width * 0.04; // 너비의 4%를 폰트 크기로 사용
    fontSizeSmall = width * 0.03; // 너비의 3%를 폰트 크기로 사용
    avatarSize = width * 0.1; // 아바타 크기를 화면 너비의 10%로 설정
  }

  @override
  initState() {
    super.initState();
    _initializeParticipantNames(); // 맵 초기화
    this._myParticipantId = widget.event.myParticipantId;
    this._myGroupParticipants = widget.event.participants.where((p)=>
    p.groupType==widget.event.memberGroup).toList();
    this._clubProfile = widget.event.club!;
    _initTeamMembers();
    _initWebSocket();
  }
  void _initializeParticipantNames() {
    _participantNames = {};
    for (var participant in widget.event.participants) {
      String name = participant.member?.name ?? 'N/A';
      print("이름: $name"); // 이름 출력
      _participantNames[participant.participantId] = name; // 맵에 추가
    }
  }


  // myGroupParticipants를 이용한 초기화
  void _initTeamMembers() {
    List<HoleScore> initialScores = List.generate(18, (index) => HoleScore(holeNumber: index + 1, score: 0));

    for (var participant in _myGroupParticipants) {
      ScoreCard scoreCard = ScoreCard(
        participantId: participant.participantId,
        userName: _participantNames[participant.participantId],
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
      // TextEditingController 초기화
      _controllers[participant.participantId] = List.generate(
        18,
            (index) => TextEditingController(text: "0"),
      );
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
    _controllers.forEach((_, controllers) => controllers.forEach((controller) => controller.dispose()));
    _focusNodes.forEach((_, nodes) => nodes.forEach((node) => node.dispose()));
    _channel.sink.close(); // WebSocket 연결 종료
    super.dispose();
  }

  void _handleWebSocketData(String data) {
    try {
      // 데이터를 파싱
      var parsedData = jsonDecode(data);

      // 데이터가 리스트인지 확인
      if (parsedData is List) {
        for (var entry in parsedData) {
          _processScoreCardEntry(entry);
        }
      }
      // 데이터가 단일 객체일 경우
      else if (parsedData is Map<String, dynamic>) {
        _processSingleScoreCardEntry(parsedData);
      } else {
        print("Unexpected data format: 데이터 형식이 List나 Map이 아닙니다.");
      }
    } catch (e) {
      print("WebSocket 데이터 처리 중 오류 발생: $e");
    }
  }
  void _processSingleScoreCardEntry(Map<String, dynamic> entry) {
    try {
      int participantId = int.parse(entry['participant_id'].toString());
      String userName = _participantNames[participantId]??'Unknown'; // 맵에서 이름 참조
      int groupType = int.parse(entry['group_type'].toString());
      String teamType = entry['team_type'];
      bool isGroupWin = entry['is_group_win'];
      bool isGroupWinHandicap = entry['is_group_win_handicap'];
      int sumScore = entry['sum_score'] ?? 0;
      int handicapScore = entry['handicap_score'] ?? 0;

      int holeNumber = entry['hole_number']; // 단일 객체에는 hole_number와 score가 포함됨
      int score = entry['score'];

      HoleScore holeScore = HoleScore(holeNumber: holeNumber, score: score);

      // 기존 참가자 정보 업데이트
      setState(() {
        // 해당 참가자의 점수 카드가 이미 존재한다면 업데이트
        if (_scorecard.containsKey(participantId)) {
          _scorecard[participantId]![holeNumber - 1] = holeScore;
          _controllers[participantId]?[holeNumber - 1].text = score.toString(); // 컨트롤러 값 업데이트
        } else {
          // 새로운 참가자라면 초기화 후 추가
          _scorecard[participantId] = List.generate(18, (index) => HoleScore(holeNumber: index + 1, score: 0));
          _scorecard[participantId]![holeNumber - 1] = holeScore;
        }

        // 팀 멤버 정보 업데이트
        _updateTeamMember(
          ScoreCard(
            participantId: participantId,
            userName: userName,
            teamType: teamType,
            groupType: groupType,
            isGroupWin: isGroupWin,
            isGroupWinHandicap: isGroupWinHandicap,
            sumScore: sumScore,
            handicapScore: handicapScore,
            scores: _scorecard[participantId],
          ),
        );
      });
    } catch (e) {
      print("단일 ScoreCard 처리 중 오류 발생: $e");
    }
  }


  void _processScoreCardEntry(Map<String, dynamic> entry) {
    try {
      // ScoreCard 객체 생성
      ScoreCard scoreCard = _parseScoreCard(entry);

      setState(() {
        _updateTeamMember(scoreCard); // 팀 멤버 업데이트
        _scorecard[scoreCard.participantId] = scoreCard.scores ?? [];
        // TextEditingController 값도 업데이트
        if (_controllers.containsKey(scoreCard.participantId)) {
          for (var holeScore in scoreCard.scores ?? []) {
            _controllers[scoreCard.participantId]?[holeScore.holeNumber - 1].text =
                holeScore.score.toString();
          }
        }
      });
    } catch (e) {
      print("ScoreCard 처리 중 오류 발생: $e");
    }
  }


// ScoreCard 객체를 생성하는 함수
  ScoreCard _parseScoreCard(Map<String, dynamic> entry) {
    int participantId = int.parse(entry['participant_id'].toString());
    String userName = _participantNames[participantId]??'Unknown'; // 맵에서 이름 참조
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
      resizeToAvoidBottomInset: false,
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
          SizedBox(height: height * 0.01), // 거리 조정
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
      padding: EdgeInsets.symmetric(vertical: height * 0.02, horizontal: width * 0.04),
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
              SizedBox(width: width * 0.03),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${widget.event.club!.name}', style: TextStyle(color: Colors.white, fontSize: fontSizeLarge)),
                  SizedBox(height: height * 0.005),
                  Text('${_formattedDate(widget.event.startDateTime)}', style: TextStyle(color: Colors.white, fontSize: fontSizeSmall)),
                ],
              ),
            ],
          ),
          SizedBox(height: height * 0.025),
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
                  child: const Text(
                    '전체 현황 조회',
                    style: TextStyle(color: Colors.white)
                  ),
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

  // Widget _buildRankIndicator(String title, String value, Color color) {
  //   return Container(
  //     padding: const EdgeInsets.all(8),
  //     decoration: BoxDecoration(
  //       color: color,
  //       borderRadius: BorderRadius.circular(8),
  //     ),
  //     child: Column(
  //       children: [
  //         Text(title, style: const TextStyle(color: Colors.white, fontSize: 12)),
  //         Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildScoreTable(int startHole, int endHole) {
    return SingleChildScrollView(
      child: Container(
        color: Colors.black,
        padding: EdgeInsets.symmetric(vertical: height * 0.0025, horizontal: width * 0.04),
        child: Table(
          columnWidths: {
            0: FixedColumnWidth(50.0), // 첫 번째 열 (홀 번호) 고정 너비
            1: FlexColumnWidth(1),    // 두 번째 열 비율로 설정
            for (int i = 2; i <= _teamMembers.length + 1; i++)
              i: FlexColumnWidth(1), // 나머지 열 비율로 설정
          },
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
        for (ScoreCard member in _teamMembers) _buildTableHeaderCell(member.userName??'Unknown'),
        // _buildTableHeaderCell('니어/롱기'),
      ],
    );
  }

  Widget _buildTableHeaderCell(String title) {
    return Container(
      color: Colors.grey[800], // 진한 회색 배경
      padding: EdgeInsets.symmetric(vertical: height * 0.005, horizontal: width * 0.01),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(color: Colors.white), // 텍스트 색상 유지
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis, // 텍스트가 넘어가면 ...으로 표시
          maxLines: 1, // 한 줄만 표시
        ),
      ),
    );
  }

  TableRow _buildEditableTableRow(int holeIndex) {
    final cellHeight = height * 0.038;
    return TableRow(
      children: [
        // 첫 번째 열: 홀 번호
        Container(
          alignment: Alignment.center, // 수직 및 수평 중앙 정렬
          height: cellHeight, // 반응형 높이 설정
          child: Text(
            (holeIndex + 1).toString(),
            style: TextStyle(color: Colors.white, fontSize: fontSizeSmall),
            textAlign: TextAlign.center,
          ),
        ),

        // 나머지 열: 참가자 점수
        ..._teamMembers.map((ScoreCard member) {
          if (_scorecard[member.participantId] != null &&
              holeIndex < _scorecard[member.participantId]!.length) {
            return Container(
              alignment: Alignment.center, // 수직 및 수평 중앙 정렬
              height: cellHeight, // 반응형 높이 설정
              child: TextFormField(
                controller: _controllers[member.participantId]?[holeIndex],
                style: TextStyle(color: Colors.white, fontSize: fontSizeSmall + 2),
                textAlign: TextAlign.center,
                inputFormatters: [AllowNegativeNumbersFormatter()],
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
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero, // 패딩 제거
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            );
          } else {
            return Container(
              alignment: Alignment.center,
              height: cellHeight, // 반응형 높이 설정
              child: const Text(
                '-',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
        }).toList(),
      ],
    );
  }


  Widget _buildSummaryTable(List<int> handiScores) {
    final cellHeight = height * 0.042; // 반응형 높이 (화면 높이의 7%)
    final cellFontSize = fontSizeSmall + 1;
    List<int> frontNine = _calculateScores(0, 9);
    List<int> backNine = _calculateScores(9, 18);
    List<int> totalScores = List.generate(
        frontNine.length, (index) => frontNine[index] + backNine[index]);
    List<int> handicapScores = handiScores;

    return Container(
      color: Colors.black,
      padding: EdgeInsets.all(width * 0.04), // 반응형 패딩
      child: Table(
        border: TableBorder.all(color: Colors.grey),
        columnWidths: {
          0: FixedColumnWidth(width * 0.2), // 첫 번째 열 (라벨 열) 너비 고정
          for (int i = 1; i <= _teamMembers.length; i++)
            i: FlexColumnWidth(1), // 나머지 열 비율로 설정
        },
        children: [
          _buildSummaryTableFirstRow(['', ..._teamMembers.map((m) => m.userName ?? 'N/A').toList()], cellHeight, cellFontSize),
          _buildSummaryTableRow(['전반', ...frontNine.map((e) => e.toString()).toList()], cellHeight, cellFontSize),
          _buildSummaryTableRow(['후반', ...backNine.map((e) => e.toString()).toList()], cellHeight, cellFontSize),
          _buildSummaryTableRow(['스코어', ...totalScores.map((e) => e.toString()).toList()], cellHeight, cellFontSize),
          _buildSummaryTableRow(['핸디 스코어', ...handicapScores.map((e) => e.toString()).toList()], cellHeight, cellFontSize),
        ],
      ),
    );
  }

  TableRow _buildSummaryTableFirstRow(List<String> cells, double cellHeight, double cellFontSize) {
    return TableRow(
      children: cells.map((cell) {
        return Container(
          alignment: Alignment.center, // 수직 및 수평 중앙 정렬
          height: cellHeight, // 반응형 높이 설정
          color: Colors.grey[800],
          child: Text(
            cell,
            style: TextStyle(color: Colors.white, fontSize: cellFontSize), // 반응형 폰트 크기 설정
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }

  TableRow _buildSummaryTableRow(List<String> cells, double cellHeight, double cellFontSize) {
    return TableRow(
      children: cells.map((cell) {
        return Container(
          alignment: Alignment.center, // 수직 및 수평 중앙 정렬
          height: cellHeight, // 반응형 높이 설정
          child: Text(
            cell,
            style: TextStyle(color: Colors.white, fontSize: cellFontSize), // 반응형 폰트 크기 설정
            textAlign: TextAlign.center,
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