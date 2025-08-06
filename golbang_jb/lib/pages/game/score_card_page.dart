import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:golbang/models/event.dart';
import 'package:golbang/pages/game/score_button_pad.dart';
import 'package:golbang/provider/screen_riverpod.dart';
import 'package:golbang/utils/reponsive_utils.dart';

import '../../services/participant_service.dart';
import '../../repoisitory/secure_storage.dart';
import '../../models/hole_score.dart';
import '../../models/participant.dart';
import '../../models/profile/club_profile.dart';
import '../../models/socket/score_card.dart';

class ScoreCardPage extends ConsumerStatefulWidget {
  final Event event;

  const ScoreCardPage({
    super.key,
    required this.event,
  });

  @override
  _ScoreCardPageState createState() => _ScoreCardPageState();
}

class _ScoreCardPageState extends ConsumerState<ScoreCardPage> with WidgetsBindingObserver, TickerProviderStateMixin {
  int _currentPageIndex = 0;
  int? _selectedHole;
  int? _selectedParticipantId;
  bool _isEditing = false;

  late final List<Participant> _participants;
  late final Map<int, String> _participantNames;
  late final List<Participant> _myGroupParticipants;
  final List<ScoreCard> _teamMembers = [];
  final Map<int, List<HoleScore>> _scorecard = {};
  final Map<int, List<FocusNode>> _focusNodes = {};
  late final ClubProfile _clubProfile;
  final Map<int, List<TextEditingController>> _controllers = {};
  // 플레이어 닉네임을 간략하게 표시하기 위한 매핑 정보
  final Map<int, String> _playerShortNames = {};
  late ParticipantService _participantService;
  int? _tempScore;

  // 페이지별 스크롤 컨트롤러 추가
  final List<ScrollController> _scrollControllers = [
    ScrollController(),
    ScrollController()
  ];

  // width와 height에 기본값 설정
  double width = 0;
  double height = 0;
  late Orientation orientation;
  late double fontSizeLarge;
  late double fontSizeMedium;
  late double fontSizeSmall;
  late double appBarIconSize;
  late double avatarSize;

  // 자동 새로고침 변수
  bool _isRefreshing = false;
  Timer? _refreshTimer;
  late final _refreshIconController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 생명주기 관찰자 등록

    _refreshIconController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // 기본 방향 설정
    orientation = Orientation.portrait;

    // 초기화할 때 screenSizeProvider 값을 읽음
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = ref.read(screenSizeProvider);
      setState(() {
        width = size.width;
        height = size.height;

        // 반응형 크기 초기화
        orientation = MediaQuery.of(context).orientation;
        fontSizeLarge = ResponsiveUtils.getLargeFontSize(width, orientation);
        fontSizeMedium = ResponsiveUtils.getMediumFontSize(width, orientation);
        fontSizeSmall = ResponsiveUtils.getSmallFontSize(width, orientation);
        appBarIconSize = ResponsiveUtils.getAppBarIconSize(width, orientation);
        avatarSize = fontSizeMedium * 2;

        // 초기화가 완료되었으므로 강제로 다시 빌드
        if (mounted) {
          setState(() {});
        }
      });
    });

    // 이벤트 및 참가자 초기화
    _clubProfile = widget.event.club!;

    _participants = widget.event.participants.where((p)=>
      p.statusType=='PARTY'||p.statusType=='ACCEPT'
    ).toList();

    // 참가자 이름 초기화
    _initializeParticipantNames();

    // 내 그룹 참가자 초기화
    _myGroupParticipants = _participants.where((p)=>
      p.groupType==widget.event.memberGroup
    ).toList();

    // 팀 멤버 및 WebSocket 초기화
    _initTeamMembers();

    // 플레이어 약어 이름 초기화
    _initPlayerShortNames();

    _participantService = ParticipantService(ref.read(secureStorageProvider));
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _getGroupScores(); // 첫 실행

    setState(() {
      _isRefreshing = true;
    });
    _refreshIconController.repeat(); // 회전 시작

    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _getGroupScores();
    });
  }

  void _stopAutoRefresh() {
    if (!mounted) return;
    _refreshTimer?.cancel();
    _refreshIconController.stop();
    _refreshIconController.reset();
    setState(() {
      _isRefreshing = false;
    });
  }

  // 플레이어 약어 이름 초기화 메서드 추가
  void _initPlayerShortNames() {
    for (int i = 0; i < _myGroupParticipants.length; i++) {
      int participantId = _myGroupParticipants[i].participantId;
      _playerShortNames[participantId] = 'P${i + 1}';
    }
  }

  void _initializeParticipantNames() {
    _participantNames = {};
    for (var participant in _participants) {
      String name = participant.member?.name ?? 'N/A';
      _participantNames[participant.participantId] = name; // 맵에 추가
    }
  }

  void _showScoreSummary() {
    _stopAutoRefresh();
    context.push(
        '/events/${widget.event.eventId}/game/scores',
        extra: {'event': widget.event}
    );
  }

  // myGroupParticipants를 이용한 초기화
  void _initTeamMembers() {
    // 초기화 시에는 점수를 null(비어있음)으로 설정
    List<HoleScore> initialScores = List.generate(18, (index) => HoleScore(holeNumber: index + 1, score: null));

    // _myGroupParticipants가 비어있는지 확인
    if (_myGroupParticipants.isEmpty) {
      log('_myGroupParticipants가 비어 있음');
      return;
    }

    // 먼저 모든 참가자를 각각의 팀 유형별로 분류
    Map<String, List<Participant>> teamParticipants = {};

    for (var participant in _myGroupParticipants) {
      if (!teamParticipants.containsKey(participant.teamType)) {
        teamParticipants[participant.teamType] = [];
      }
      teamParticipants[participant.teamType]!.add(participant);
    }

    log('팀 유형별 참가자 분류: ${teamParticipants.keys.length} 팀');

    // 각 팀 유형별로 참가자 추가
    for (var teamType in teamParticipants.keys) {
      for (var participant in teamParticipants[teamType]!) {
        String userName = _participantNames[participant.participantId] ?? 'Unknown';
        log('팀원 추가: $userName (ID: ${participant.participantId}, 팀: $teamType)');

        ScoreCard scoreCard = ScoreCard(
          participantId: participant.participantId,
          userName: userName,
          teamType: participant.teamType,
          groupType: participant.groupType,
          isGroupWin: false,
          isGroupWinHandicap: false,
          sumScore: participant.sumScore ?? 0,
          handicapScore: participant.handicapScore?? 0,
          scores: initialScores,
        );

        _teamMembers.add(scoreCard);
        _scorecard[participant.participantId] = List.from(initialScores);

        // TextEditingController 초기화 - 빈 문자열로 초기화하여 하이픈으로 표시
        _controllers[participant.participantId] = List.generate(
          18,
          (index) => TextEditingController(text: ""),
        );

        // 각 참가자별로 18개의 FocusNode를 생성하여 저장
        _focusNodes[participant.participantId] = List.generate(18, (_) => FocusNode());
      }
    }

    log('초기화된 팀 멤버: ${_teamMembers.length}명');

    setState(() {});
  }


  @override
  void dispose() {
    _refreshTimer?.cancel();
    _refreshIconController.dispose();
    WidgetsBinding.instance.removeObserver(this); // 생명주기 관찰자 제거
    _controllers.forEach((_, controllers) => controllers.forEach((controller) => controller.dispose()));
    _focusNodes.forEach((_, nodes) => nodes.forEach((node) => node.dispose()));
    // 스크롤 컨트롤러 해제
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _postScore({
    required int eventId,
    required int participantId,
    required int holeNumber,
  }) async {
    try {
      // 비우기(지우기) 기능: _tempScore가 null이면 빈 스코어로 저장
      if (_tempScore == null) {
        final result = await _participantService.postStrokeScore(
          eventId: eventId,
          participantId: participantId,
          holeNumber: holeNumber,
          score: null, // 빈 값 전송
        );

        // 서버에서 ScoreCard 응답이 올 수 있으므로 처리
        if (result != null) {
          _processSingleScoreCardEntry(result, holeNumber, null);
        }

        setState(() {
          _scorecard[_selectedParticipantId]![_selectedHole! - 1] =
              HoleScore(holeNumber: _selectedHole!, score: null);

          // 컨트롤러 텍스트를 빈값으로 설정하여 하이픈 표시
          _controllers[_selectedParticipantId]?[_selectedHole! - 1].text = "";

          _isEditing = false;
          _selectedHole = null;
          _selectedParticipantId = null;
          _tempScore = null;
        });
        return; // 비우기 처리 후 종료
      }

      final result = await _participantService.postStrokeScore(
        eventId: eventId,
        participantId: participantId,
        holeNumber: holeNumber,
        score: _tempScore,
      );

      if (result == null) return;

      _processSingleScoreCardEntry(result, holeNumber, _tempScore);

      setState(() {
        _scorecard[_selectedParticipantId]![_selectedHole! - 1] =
            HoleScore(holeNumber: _selectedHole!, score: _tempScore);

        _controllers[_selectedParticipantId]?[_selectedHole! - 1].text =
        _tempScore != null ? _tempScore.toString() : "";

        _isEditing = false;
        _selectedHole = null;
        _selectedParticipantId = null;
        _tempScore = null;
      });
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('스코어 등록 실패'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                child: const Text('확인'),
                onPressed: () => context.pop()
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _getGroupScores() async {
    try {
      final result = await _participantService.getGroupScores(
        eventId: widget.event.eventId,
        groupType: widget.event.memberGroup,
      );

      for (var p in result!) {
        _processScoreCardEntry(p);
      }

    } catch (e) {
      _stopAutoRefresh();

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('스코어 조회 실패'),
            content: Text('$e'),
            actions: [
              TextButton(
                child: const Text('확인'),
                onPressed: () => context.pop()
              ),
            ],
          ),
        );
      }
    }
  }


  void _processSingleScoreCardEntry(ScoreCard entry, int holeNumber, int? score) {
    try {
      log('단일 스코어카드 처리: participantId=${entry.participantId}');

      // 해당 참가자의 점수 카드가 이미 존재한다면 업데이트
      if (_scorecard.containsKey(entry.participantId)) {
        _scorecard[entry.participantId]![holeNumber - 1] = HoleScore(holeNumber: holeNumber, score: score);

        // 서버에서 null 값은 하이픈으로 처리, 그 외는 실제 점수로 처리
        if (score == null) {
          _controllers[entry.participantId]?[holeNumber - 1].text = "";
        } else {
          _controllers[entry.participantId]?[holeNumber - 1].text = score.toString();
        }
      } else {
        // 새로운 참가자라면 초기화 후 추가
        _scorecard[entry.participantId] = List.generate(18, (index) => HoleScore(holeNumber: index + 1, score: null));
        _scorecard[entry.participantId]![holeNumber - 1] = HoleScore(holeNumber: holeNumber, score: score);

        // 새로운 컨트롤러도 생성해야 하는 경우
        if (!_controllers.containsKey(entry.participantId)) {
          _controllers[entry.participantId] = List.generate(18, (index) => TextEditingController(text: ""));
        }

        // 서버에서 null 값은 하이픈으로 처리, 그 외는 실제 점수로 처리
        if (score == null) {
          _controllers[entry.participantId]?[holeNumber - 1].text = "";
        } else {
          _controllers[entry.participantId]?[holeNumber - 1].text = score.toString();
        }
      }

      // 팀 멤버 정보 업데이트
      bool isMyGroupMember = _myGroupParticipants.any((p) => p.participantId == entry.participantId);

      if (isMyGroupMember) {
        _updateTeamMember(entry);
      }
      // 상태 업데이트
      setState(() {});
    } catch (e) {
      log("단일 ScoreCard 처리 중 오류 발생: $e");
    }
  }

  void _processScoreCardEntry(ScoreCard scoreCard) {
    try {
      // ScoreCard 객체 생성
      int participantId = scoreCard.participantId;

      // 해당 참가자가 내 그룹 소속인지 확인
      bool isMyGroupMember = _myGroupParticipants.any((p) => p.participantId == participantId);
      log('isMyGroupMember: $isMyGroupMember');
      if (!isMyGroupMember) {
        // 내 그룹 소속이 아니면 처리하지 않음
        return;
      }

      _updateTeamMember(scoreCard); // 팀 멤버 업데이트

      List<HoleScore> filledScores = List.generate(18, (index) {
        return scoreCard.scores?.firstWhere(
              (s) => s.holeNumber == index + 1,
          orElse: () => HoleScore(holeNumber: index + 1, score: null),
        ) ?? HoleScore(holeNumber: index + 1, score: null);
      });

      _scorecard[scoreCard.participantId] = filledScores;

      // TextEditingController 값도 업데이트
      if (_controllers.containsKey(scoreCard.participantId)) {
        for (var holeScore in scoreCard.scores ?? []) {
          int holeIndex = holeScore.holeNumber - 1;
          // 서버에서 null 값은 하이픈으로 처리, 그 외는 실제 점수로 처리
          if (holeScore.score == null) {
            _controllers[scoreCard.participantId]?[holeIndex].text = "";
          } else {
            _controllers[scoreCard.participantId]?[holeIndex].text = holeScore.score.toString();
          }
          setState(() {}); // 없으면, 스코어 표시 안됨.
        }
      }
    } catch (e) {
      log("ScoreCard 처리 중 오류 발생: $e");
    }
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

  @override
  Widget build(BuildContext context) {
    // 현재 상태 로깅
    if (_selectedHole != null) {
      log('빌드 - _selectedHole: $_selectedHole, _isEditing: $_isEditing');
    }

    // WebSocket 연결 또는 초기화 중이거나 데이터 로딩 중일 때 공통 로딩 화면 표시
    if ( width < 10 || height < 10 || _teamMembers.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('로딩 중...', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Colors.white,
            onPressed: () => context.pop()
          ),
        ),
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // 키보드가 활성화된 상태인지 확인
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: !_isEditing ? AppBar(
        title: Text(widget.event.eventTitle, style: TextStyle(color: Colors.white, fontSize: fontSizeLarge)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: appBarIconSize),
          color: Colors.white,
          onPressed: () => context.pop()
        ),
        actions: [
          AnimatedBuilder(
            animation: _refreshIconController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshIconController.value * 6.3,
                child: child,
              );
            },
            child: IconButton(
              icon: Icon(Icons.refresh, size: appBarIconSize),
              color: Colors.white,
              onPressed: _isRefreshing ? _stopAutoRefresh : _startAutoRefresh,
              tooltip: '새로고침',
            ),
          ),
        ],
      ): null,
      body: SafeArea(
        top: true, bottom: true,
        child: Column(
          children: [
            // 키보드가 보이지 않을 때만 헤더를 보여줌
            isKeyboardVisible
                ? Container(
              height: 10,
              color: Colors.red,
            )
                : _buildHeader(),
            // 플레이어 범례를 페이지 전환과 독립적으로 배치
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildPlayerLegend(),
            ),
            SizedBox(height: height * 0.01),
            Expanded(
              child: Column(
                children: [
                  Flexible(
                    child: PageView(
                      controller: PageController(initialPage: _currentPageIndex),
                      onPageChanged: (index) {
                        setState(() {
                          _currentPageIndex = index;
                        });
                      },
                      children: [
                        _buildScoreTable(1, 9, 0),
                        _buildScoreTable(10, 18, 1),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomSheet: Column(
          mainAxisSize: MainAxisSize.min,
          children:[
            _buildPageIndicator(),
            !_isEditing
            ? _buildSummaryTable(_teamMembers.map((m) => m.handicapScore).toList())
            : ScoreButtonPadStateful(
            selectedHole: _selectedHole,
            isEditing: _isEditing,
            onComplete: () => _postScore(
              eventId: widget.event.eventId, // 이 부분도 실제 eventId 변수로 수정해야 해요
              participantId: _selectedParticipantId!,
              holeNumber: _selectedHole!,
            ),
            onScoreChanged: (int? score) {
              log('tempScore변환전: $_tempScore');

              setState(() {
                _tempScore = score; // null 허용
              });
              log('tempScore변환후: $_tempScore');
            },
            tempScore: _tempScore,
            onEdit: null,
            onCancelScoreEdit: _cancelScoreEdit,
            width: width,
            height: height,
            fontSizeLarge: fontSizeLarge,
            fontSizeMedium: fontSizeMedium
          ),
        ]
      ),
      backgroundColor: Colors.black,
    );
  }

  void _cancelScoreEdit() {
    setState(() {
      _isEditing = false;
      _selectedHole = null;
      _selectedParticipantId = null;
      _selectedParticipantId = null;
      _tempScore = null;
    });
  }

  String _formattedDate(DateTime dateTime) {
    return dateTime.toIso8601String().split('T').first; // T 문자로 나누고 첫 번째 부분만 가져옴
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.symmetric(vertical: height * 0.01, horizontal: width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isEditing) ...[
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: _clubProfile.image.startsWith('https')
                      ? NetworkImage(_clubProfile.image)
                      : AssetImage(_clubProfile.image) as ImageProvider,
                  backgroundColor: Colors.transparent,
                  radius: avatarSize,
                ),
                SizedBox(width: width * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.event.club!.name, style: TextStyle(color: Colors.white, fontSize: fontSizeLarge)),
                      SizedBox(height: height * 0.005),
                      Text(_formattedDate(widget.event.startDateTime), style: TextStyle(color: Colors.white, fontSize: fontSizeMedium)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _showScoreSummary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.01),
                  ),
                  child: Text(
                    '전체 현황 조회',
                    style: TextStyle(color: Colors.white, fontSize: fontSizeMedium)
                  ),
                ),
              ],
            ),
            SizedBox(height: height * 0.001), // 간격 줄임
          ],
        ],
      ),
    );
  }

  Widget _buildScoreTable(int startHole, int endHole, int pageIndex) {
    return SingleChildScrollView(
      controller: _scrollControllers[pageIndex],
      child: Container(
        color: Colors.black,
        padding: EdgeInsets.symmetric(vertical: height * 0.0025, horizontal: width * 0.04),
        child: Table(
          columnWidths: {
            0: const FixedColumnWidth(50.0),
            for (int i = 1; i <= _teamMembers.length; i++)
              i: const FlexColumnWidth(1),
            _teamMembers.length + 1: const FixedColumnWidth(80.0),
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

  // 플레이어 범례 위젯 수정
  Widget _buildPlayerLegend() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _teamMembers.map((member) {
          String shortName = _playerShortNames[member.participantId] ?? 'P?';
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$shortName: ${member.userName ?? 'Unknown'}',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSizeSmall,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  TableRow _buildTableHeaderRow() {
    return TableRow(
      children: [
        _buildTableHeaderCell('홀'),
        for (ScoreCard member in _teamMembers)
          _buildTableHeaderCell(_playerShortNames[member.participantId] ?? 'P?'),
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
          style: TextStyle(color: Colors.white, fontSize: fontSizeLarge), // 텍스트 색상 유지
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis, // 텍스트가 넘어가면 ...으로 표시
          maxLines: 1, // 한 줄만 표시
        ),
      ),
    );
  }

  TableRow _buildEditableTableRow(int holeIndex) {
    final cellHeight = height * 0.038;
    final holeNumber = holeIndex + 1;
    // log('홀 $holeNumber 상태: isCompleted=$isHoleCompleted, allScoresEntered=$allScoresEntered');

    return TableRow(
      children: [
        // 홀 번호 셀 - 완료된 홀은 체크 아이콘 표시
        Container(
          alignment: Alignment.center,
          height: cellHeight,
          // color: isHoleCompleted ? Colors.green.withOpacity(0.2) : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                holeNumber.toString(),
                style: TextStyle(color: Colors.white, fontSize: fontSizeMedium),
                textAlign: TextAlign.center,
              ),
              // if (isHoleCompleted)
              // Icon(Icons.check_circle, color: Colors.green, size: fontSizeMedium),
            ],
          ),
        ),
        // 참가자별 점수 셀
        ..._teamMembers.map((ScoreCard member) {
          final score = _scorecard[member.participantId]?[holeIndex].score;
          final isSelected = _selectedHole == holeNumber &&
                           _selectedParticipantId == member.participantId;

          // 컨트롤러의 텍스트가 비어 있거나 점수가 null이면 대시로 표시
          final String controllerText = _controllers[member.participantId]?[holeIndex].text ?? '';
          final String displayText = (controllerText.isEmpty || score == null) ? '-' : score.toString();

          return GestureDetector(
            onTap: () {
              log('셀 탭: holeIndex=$holeNumber, participantId=${member.participantId}');
              _handleCellSelection(holeNumber, member.participantId);
            },
            child: Container(
              alignment: Alignment.center,
              height: cellHeight,
              decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                  )
                : const BoxDecoration(),
              child: Text(
                displayText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSizeMedium,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSummaryTable(List<int> handiScores) {
    final cellHeight = height * 0.042; // 반응형 높이 (화면 높이의 7%)
    final cellFontSize = fontSizeMedium;
    List<int> frontNine = _calculateScores(0, 9);
    List<int> backNine = _calculateScores(9, 18);
    List<int> totalScores = List.generate(
        frontNine.length, (index) => frontNine[index] + backNine[index]);
    List<int> handicapScores = handiScores;

    return SafeArea(
      top: true, bottom: true,
      child: Container(
        color: Colors.black,
        padding: EdgeInsets.all(width * 0.04), // 반응형 패딩
        child: Table(
          border: TableBorder.all(color: Colors.grey),
          columnWidths: {
            0: FixedColumnWidth(width * 0.2), // 첫 번째 열 (라벨 열) 너비 고정
            for (int i = 1; i <= _teamMembers.length; i++)
              i: const FlexColumnWidth(1), // 나머지 열 비율로 설정
          },
          children: [
            _buildSummaryTableFirstRow(['', ..._teamMembers.map((m) => _playerShortNames[m.participantId] ?? 'P?')], cellHeight, cellFontSize),
            _buildSummaryTableRow(['전반', ...frontNine.map((e) => e.toString())], cellHeight, cellFontSize),
            _buildSummaryTableRow(['후반', ...backNine.map((e) => e.toString())], cellHeight, cellFontSize),
            _buildSummaryTableRow(['스코어', ...totalScores.map((e) => e.toString())], cellHeight, cellFontSize),
            _buildSummaryTableRow(['핸디 스코어', ...handicapScores.map((e) => e.toString())], cellHeight, cellFontSize),
          ],
        ),
      )
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

      // 참가자의 scorecard에서 홀 점수를 더함
      for (int j = start; j < end; j++) {
        // 참가자의 _scorecard에 저장된 홀 점수에서 j번째 홀 점수를 가져와 더함
        if (_scorecard[participantId] != null && j < _scorecard[participantId]!.length) {
          int? score = _scorecard[participantId]![j].score;
          // null(하이픈)이 아닌 경우에만 점수 합산
          if (score != null) {
            sum += score;
          }
        }
      }
      return sum;
    });
  }

  Widget _buildPageIndicator() {
    return Container(
      color: Colors.black, // 💡 여기!
      padding: const EdgeInsets.only(
        top: 0, // ← 여기를 줄여봄
        bottom: 25,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIndicatorDot(0),
          const SizedBox(width: 8),
          _buildIndicatorDot(1),
        ],
      ),
    );
  }

  Widget _buildIndicatorDot(int index) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPageIndex == index ? Colors.yellow : Colors.white,
        border: Border.all(
          color: Colors.white, // 흰색 테두리로 항상 보이게
          width: 1.5,
        ),
      ),
    );
  }

  // 셀 선택 처리 수정 - 스크롤 위치 조정 추가
  void _handleCellSelection(int holeNumber, int participantId) {
    log('셀 선택: holeNumber=$holeNumber, participantId=$participantId');

    // 선택 전에 먼저 현재 셀이 속한 페이지로 전환
    final targetPageIndex = (holeNumber <= 9) ? 0 : 1;
    if (_currentPageIndex != targetPageIndex) {
      setState(() {
        _currentPageIndex = targetPageIndex;
      });

      // 페이지 전환에 약간의 지연 필요
      Future.delayed(const Duration(milliseconds: 50), () {
        _processSelection(holeNumber, participantId);
      });
      return;
    }

    // 같은 페이지면 바로 처리
    _processSelection(holeNumber, participantId);
  }

  // 실제 셀 선택 로직 처리
  void _processSelection(int holeNumber, int participantId) {

    setState(() {
      _selectedHole = holeNumber;
      _selectedParticipantId = participantId;
      _isEditing = true;
      int? score = _scorecard[participantId]?[holeNumber - 1].score;
      // null(하이픈)인 경우 null로 설정
      _tempScore = score;
    });

    // 상태 변경 후 로깅
    log('셀 선택 후: _selectedHole=$_selectedHole, _selectedParticipantId=$_selectedParticipantId, _isEditing=$_isEditing, _tempScore=$_tempScore');
  }

}