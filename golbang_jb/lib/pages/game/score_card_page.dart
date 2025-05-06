import 'dart:async';
import 'dart:collection';
import 'dart:developer';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/models/event.dart';
import 'package:golbang/pages/game/overall_score_page.dart';
import 'package:golbang/provider/screen_riverpod.dart';
import 'package:golbang/utils/AllowNavigateNumbersFormatter.dart';
import 'package:golbang/utils/reponsive_utils.dart';
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

class _ScoreCardPageState extends ConsumerState<ScoreCardPage> with WidgetsBindingObserver {
  int _currentPageIndex = 0;
  int? _selectedHole;
  int? _selectedParticipantId;
  bool _isEditing = false;
  int? _tempScore;
  Map<String, Color> _cellColors = {};

  late final WebSocketChannel _channel;
  late final List<Participant> _participants;
  late final Map<int, String> _participantNames;
  late final int _myParticipantId;
  late final List<Participant> _myGroupParticipants;
  final List<ScoreCard> _teamMembers = [];
  final Map<int, List<HoleScore>> _scorecard = {};
  final Map<int, List<FocusNode>> _focusNodes = {};
  late final ClubProfile _clubProfile;
  final Map<int, List<TextEditingController>> _controllers = {};
  // 플레이어 닉네임을 간략하게 표시하기 위한 매핑 정보
  final Map<int, String> _playerShortNames = {};
  
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

  bool _isWebSocketConnected = false;
  bool _isReconnecting = false;
  Timer? _reconnectTimer;
  final Queue<Map<String, dynamic>> _messageQueue = Queue();
  static const int MAX_RETRY_COUNT = 5;
  int _retryCount = 0;
  bool _initialConnectionAttempt = true;
  bool _isInitialLoading = true;
  bool _isAppResumed = false;
  Timer? _resumeRetryTimer; // 재연결 시도 타이머 추가
  int _resumeRetryCount = 0; // 재연결 시도 횟수 추가
  bool _isWebSocketInitialized = false; // WebSocket 초기화 상태
  bool _isWaitingForData = false; // 데이터 응답 대기 상태

  // 홀이 완료됐는지 여부를 저장하는 Map (key: 홀 번호, value: 완료 여부)
  final Map<int, bool> _completedHoles = {};
  
  // 현재 선택된 홀이 완료되었는지 확인
  bool get _isSelectedHoleCompleted => _selectedHole != null ? _completedHoles[_selectedHole!] ?? false : false;
  
  bool _receivedConfirmation = false; // 점수 저장 응답 수신 여부
  bool _receivedPong = false; // ping에 대한 pong 응답 수신 여부
  bool _receivedCheckResponse = false; // 연결 확인 응답 수신 여부
  DateTime? _lastMessageSentTime; // 마지막 메시지 전송 시간
  Timer? _pingTimer; // ping 전송 타이머
  Timer? _loadingTimeoutTimer; // 로딩 타임아웃 타이머
  String _lastActionType = ""; // 마지막으로 수행한 액션 타입
  int _lastActionHoleNumber = 0; // 마지막으로 작업한 홀 번호

  bool _isRefreshCooldown = false; // 새로고침 쿨다운 상태
  Timer? _refreshCooldownTimer; // 새로고침 쿨다운 타이머

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // 생명주기 관찰자 등록
    
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
    _myParticipantId = widget.event.myParticipantId;
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
    _initWebSocket();
    
    // 플레이어 약어 이름 초기화
    _initPlayerShortNames();
    
    
    // 주기적 연결 상태 확인 타이머 설정
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isWebSocketConnected && mounted) {
        _checkConnectionStatus();
      }
    });
    
    // 로딩 타임아웃 타이머 설정
    _startLoadingTimeoutTimer();
  }

  void _initializeParticipantNames() {
    _participantNames = {};
    for (var participant in _participants) {
      String name = participant.member?.name ?? 'N/A';
      _participantNames[participant.participantId] = name; // 맵에 추가
    }
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

  Future<void> _initWebSocket() async {
    // 연결 시도 허용을 위해 조건 제거
    // if (_isReconnecting) return;

    try {
      SecureStorage secureStorage = ref.read(secureStorageProvider);
      final accessToken = await secureStorage.readAccessToken();
      
      log('WebSocket 연결 시도 중...');
      
      // 기존 연결이 있으면 닫기
      try {
        _channel.sink.close();
      } catch (e) {
        log('기존 WebSocket 연결 닫기 실패: $e');
      }
      
      _channel = IOWebSocketChannel.connect(
        Uri.parse('${dotenv.env['WS_HOST']}/participants/$_myParticipantId/group/stroke'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      _channel.stream.listen(
        (data) {
          if (!mounted) return;
          
          log('WebSocket 데이터 수신: $data');
          setState(() {
            _isWebSocketConnected = true;
            _isWebSocketInitialized = true;
            _initialConnectionAttempt = false;
            _retryCount = 0;
            _isReconnecting = false; // 연결 성공 시 재연결 중 상태 해제
          });
          
          // 초기 로딩 상태 해제
          if (_isInitialLoading) {
            setState(() {
              _isInitialLoading = false;
              _isAppResumed = false;
            });
          }
          
          _handleWebSocketData(data);
          
          // 연결이 복구되면 대기 중인 메시지 처리
          _processQueuedMessages();
        },
        onError: (error) {
          log('WebSocket 오류 발생: $error');
          setState(() {
            _isWebSocketConnected = false;
            _isWebSocketInitialized = false;
          });
          
          // 초기 로딩 중 오류는 무시하고 로딩 상태 유지
          if (!_initialConnectionAttempt && mounted) {
            _handleWebSocketError(error);
          }
        },
        onDone: () {
          log('WebSocket 연결 종료');
          setState(() {
            _isWebSocketConnected = false;
            _isWebSocketInitialized = false;
          });
          
          // 초기 로딩 중 연결 종료는 무시
          if (!_initialConnectionAttempt && mounted) {
            _showReconnectDialog();
          }
        },
      );
      
      
    } catch (e) {
      log('WebSocket 초기화 오류: $e');
      setState(() {
        _isWebSocketInitialized = false;
      });
    }
    
    // WebSocket 초기화 시 로딩 타임아웃 타이머 재시작
    _startLoadingTimeoutTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 생명주기 관찰자 제거
    _controllers.forEach((_, controllers) => controllers.forEach((controller) => controller.dispose()));
    _focusNodes.forEach((_, nodes) => nodes.forEach((node) => node.dispose()));
    _reconnectTimer?.cancel();
    _resumeRetryTimer?.cancel(); // 재연결 시도 타이머 해제
    // 스크롤 컨트롤러 해제
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    _channel.sink.close();
    _pingTimer?.cancel(); // ping 타이머 해제
    _loadingTimeoutTimer?.cancel(); // 로딩 타임아웃 타이머 취소
    _refreshCooldownTimer?.cancel(); // 새로고침 쿨다운 타이머 취소
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 앱이 포그라운드로 돌아왔을 때
      setState(() {
        _isAppResumed = true;
        _isInitialLoading = true;
      });
      
      if (_isWebSocketConnected) {
        // WebSocket이 연결되어 있으면 데이터만 새로고침
        log('WebSocket 연결 유지 - 데이터 새로고침');
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                _handleRefresh();
              }
            });
      } else {
        // WebSocket이 연결되어 있지 않으면 재연결 시도
        log('WebSocket 연결 없음 - 재연결 시도');
        _startResumeRetry();
      }
    } else if (state == AppLifecycleState.paused) {
      // 앱이 백그라운드로 갈 때
      _resumeRetryTimer?.cancel(); // 재연결 시도 중단
    }
    
    // 앱이 포그라운드로 돌아왔을 때 로딩 타임아웃 타이머 재시작
    _startLoadingTimeoutTimer();
  }

  // 재연결 시도 시작
  void _startResumeRetry() {
    _resumeRetryTimer?.cancel(); // 기존 타이머 취소
    
    _resumeRetryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_resumeRetryCount >= MAX_RETRY_COUNT) {
        // 최대 시도 횟수 초과
        timer.cancel();
        setState(() {
          _isInitialLoading = false;
          _isAppResumed = false;
        });
        return;
      }
      
      if (!_isWebSocketConnected) {
        _resumeRetryCount++;
        log('재연결 시도: $_resumeRetryCount/$MAX_RETRY_COUNT');
        
        // 기존 WebSocket 연결 닫기
        try {
          _channel.sink.close();
        } catch (e) {
          log('기존 WebSocket 연결 닫기 실패: $e');
        }
        
        _initWebSocket();
      } else {
        // 연결 성공
        timer.cancel();
        log('success');
        setState(() {
          _isInitialLoading = false;
          _isAppResumed = false;
        });
      }
    });
  }

  void _handleWebSocketData(String data) {
    // 데이터를 받으면 로딩 타임아웃 타이머 취소
    _loadingTimeoutTimer?.cancel();
    
    try {
      log('WebSocket 데이터 수신: $data');
      
      // 데이터를 파싱
      var parsedData = jsonDecode(data);
      
      // 모든 데이터 수신은 연결 확인으로 간주
      _receivedCheckResponse = true;
      
      // 오류 응답 체크
      if (parsedData['status'] != null && parsedData['error'] != null) {
        log('오류 응답 수신: ${parsedData['error']}');
        return;
      }
      
      // 더 이상 사용하지 않음 (서버가 ping을 지원하지 않음)
      // if (parsedData['type'] == 'pong') {
      //   log('pong 응답 수신');
      //   _receivedPong = true;
      //   return;
      // }
      
      // 점수 입력/수정 확인 처리
      if (parsedData['type'] == 'input_score' || parsedData['type'] == 'broadcast_scores') {
        log('점수 입력/수정 메시지 수신: type=${parsedData['type']}, hole=${parsedData['hole_number']}');
        
        // input_score 타입이거나 broadcast_scores 타입인데 마지막 액션이 점수 입력이었고 홀 번호가 일치하면 확인으로 처리
        if (parsedData['type'] == 'input_score' || 
            (_lastActionType == 'post' && 
             parsedData['hole_number'] == _lastActionHoleNumber)) {
          log('점수 입력 확인: ${_receivedConfirmation} -> true');
          _receivedConfirmation = true;
        }
        
        _processSingleScoreCardEntry(parsedData);
        return;
      }
      
      // type이 confirm_hole인 경우 (홀 확인 시)
      if (parsedData['type'] == 'confirm_hole') {
        log('홀 확인 메시지 수신: hole=${parsedData['hole_number']}');
        
        // 마지막 액션이 홀 완료였고 홀 번호가 일치하면 확인으로 처리
        if (_lastActionType == 'confirm_hole' && 
            parsedData['hole_number'] == _lastActionHoleNumber) {
          log('홀 완료 확인: ${_receivedConfirmation} -> true');
          _receivedConfirmation = true;
        }
        
        int holeNumber = parsedData['hole_number'];
        setState(() {
          _completedHoles[holeNumber] = true;
        });
        return;
      }
      
      // type이 uncheck_hole인 경우 (홀 수정 시)
      if (parsedData['type'] == 'uncheck_hole') {
        log('홀 수정 메시지 수신: hole=${parsedData['hole_number']}');
        
        // 마지막 액션이 홀 수정이었고 홀 번호가 일치하면 확인으로 처리
        if (_lastActionType == 'uncheck_hole' && 
            parsedData['hole_number'] == _lastActionHoleNumber) {
          log('홀 수정 확인: ${_receivedConfirmation} -> true');
          _receivedConfirmation = true;
        }
        
        int holeNumber = parsedData['hole_number'];
        setState(() {
          _completedHoles[holeNumber] = false;
        });
        return;
      }
      
      // scores 데이터가 있는 경우에도 점수 업데이트로 간주
      if (parsedData['scores'] != null) {
        // 데이터를 받았으므로 연결이 유지되고 있다고 판단
        log('scores 데이터 수신 - WebSocket 연결 유지 중');
        _receivedConfirmation = true;
      }
      
      // hole_checks 데이터 처리
      if (parsedData['hole_checks'] != null) {
        Map<String, dynamic> holeChecks = parsedData['hole_checks'];
        log('hole_checks 데이터 수신: $holeChecks');
        
        setState(() {
          // 모든 홀의 체크 상태를 초기화
          _completedHoles.clear();
          // 서버에서 받은 체크 상태로 업데이트
          holeChecks.forEach((holeNumber, isChecked) {
            int holeNum = int.parse(holeNumber);
            _completedHoles[holeNum] = isChecked;
            log('홀 $holeNum 체크 상태 업데이트: $isChecked');
          });
        });
      }

      // scores 데이터 처리
      if (parsedData['scores'] != null) {
        var scoresData = parsedData['scores'];
        
        // 연결이 복구되었음을 표시
        setState(() {
          _isWebSocketConnected = true;
          _isReconnecting = false;
          _isWaitingForData = false;
        });

        // 데이터가 리스트인지 확인
        if (scoresData is List) {
          log('리스트 데이터 수신: ${scoresData.length}개');
          for (var entry in scoresData) {
            _processScoreCardEntry(entry);
          }
        }
        // 데이터가 단일 객체일 경우
        else if (scoresData is Map<String, dynamic>) {
          log('단일 객체 데이터 수신');
          _processSingleScoreCardEntry(scoresData);
        } else {
          log("Unexpected data format: scores 데이터 형식이 List나 Map이 아닙니다.");
        }
      }
      
      // 상태 업데이트 후 로깅
      log('현재 _completedHoles 상태: $_completedHoles');
      
    } catch (e) {
      log("WebSocket 데이터 처리 중 오류 발생: $e");
      setState(() {
        _isWaitingForData = false;
      });
    }
  }

  void _processSingleScoreCardEntry(Map<String, dynamic> entry) {
    try {
      int participantId = int.parse(entry['participant_id'].toString());
      String userName = _participantNames[participantId] ?? 'Unknown';
      int groupType = int.parse(entry['group_type'].toString());
      String teamType = entry['team_type'];
      bool isGroupWin = entry['is_group_win'];
      bool isGroupWinHandicap = entry['is_group_win_handicap'];
      int sumScore = entry['sum_score'] ?? 0;
      int handicapScore = entry['handicap_score'] ?? 0;

      int holeNumber = entry['hole_number'];
      int? score = entry['score'];

      log('단일 스코어카드 처리: participantId=$participantId, holeNumber=$holeNumber, score=$score');

      // 해당 참가자의 점수 카드가 이미 존재한다면 업데이트
      if (_scorecard.containsKey(participantId)) {
        _scorecard[participantId]![holeNumber - 1] = HoleScore(holeNumber: holeNumber, score: score);
        
        // 서버에서 null 값은 하이픈으로 처리, 그 외는 실제 점수로 처리
        if (score == null) {
          _controllers[participantId]?[holeNumber - 1].text = "";
        } else {
          _controllers[participantId]?[holeNumber - 1].text = score.toString();
        }
      } else {
        // 새로운 참가자라면 초기화 후 추가
        _scorecard[participantId] = List.generate(18, (index) => HoleScore(holeNumber: index + 1, score: null));
        _scorecard[participantId]![holeNumber - 1] = HoleScore(holeNumber: holeNumber, score: score);
        
        // 새로운 컨트롤러도 생성해야 하는 경우
        if (!_controllers.containsKey(participantId)) {
          _controllers[participantId] = List.generate(18, (index) => TextEditingController(text: ""));
        }
        
        // 서버에서 null 값은 하이픈으로 처리, 그 외는 실제 점수로 처리
        if (score == null) {
          _controllers[participantId]?[holeNumber - 1].text = "";
        } else {
          _controllers[participantId]?[holeNumber - 1].text = score.toString();
        }
      }

      // 팀 멤버 정보 업데이트
      bool isMyGroupMember = _myGroupParticipants.any((p) => p.participantId == participantId);
      
      if (isMyGroupMember) {
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
      }

      // 상태 업데이트
      setState(() {});
    } catch (e) {
      log("단일 ScoreCard 처리 중 오류 발생: $e");
    }
  }

  void _processScoreCardEntry(Map<String, dynamic> entry) {
    try {
      // ScoreCard 객체 생성
      ScoreCard scoreCard = _parseScoreCard(entry);
      int participantId = scoreCard.participantId;
      
      // 해당 참가자가 내 그룹 소속인지 확인
      bool isMyGroupMember = _myGroupParticipants.any((p) => p.participantId == participantId);
      
      if (!isMyGroupMember) {
        // 내 그룹 소속이 아니면 처리하지 않음
        return;
      }

      _updateTeamMember(scoreCard); // 팀 멤버 업데이트
      _scorecard[scoreCard.participantId] = scoreCard.scores ?? [];
      
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
        }
      }
    } catch (e) {
      log("ScoreCard 처리 중 오류 발생: $e");
    }
  }

  // ScoreCard 객체를 생성하는 함수
  ScoreCard _parseScoreCard(Map<String, dynamic> entry) {
    print("hhh");
    print(entry);
    int participantId = int.parse(entry['participant_id'].toString());
    String userName = _participantNames[participantId] ?? 'Unknown'; // 맵에서 이름 참조
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
    print('hi');
    print(scoresJson);
    // 초기 스코어는 null(비어있음)으로 설정
    List<HoleScore> scores = List.generate(18, (index) => HoleScore(holeNumber: index + 1, score: null));

    for (var scoreData in scoresJson) {
      int holeNumber = scoreData['hole_number'];
      int? score = scoreData['score']; // 서버에서 null로 올 수 있음
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
    final message = {
      'action': 'post',
      'participant_id': participantId,
      'hole_number': holeNumber,
      'score': score,
    };

    if (_isWebSocketConnected) {
      _channel.sink.add(jsonEncode(message));
    } else {
      _addToMessageQueue(message);
      _showReconnectDialog();
    }

    _scorecard[participantId]![holeNumber - 1] = HoleScore(
      holeNumber: holeNumber,
      score: score,
    );
  }

  // 서버에 새로고침 요청을 보내는 함수
  Future<void> _handleRefresh() async {
    if (!mounted) return;
    
    // 이미 데이터를 기다리는 중이거나 쿨다운 중이면 요청 방지
    if (_isWaitingForData || _isRefreshCooldown) {
      log(_isWaitingForData ? '이미 데이터 새로고침 중입니다' : '새로고침 쿨다운 중입니다 (5초)');
      
      // 쿨다운 중일 때 스낵바로 알림
      if (mounted) {
        final remainingTime = _refreshCooldownTimer != null ? 
            5 - _refreshCooldownTimer!.tick : 5;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isWaitingForData 
                ? '데이터를 가져오는 중입니다. 잠시만 기다려주세요.'
                : '${remainingTime > 0 ? remainingTime : 5}초 후에 다시 시도할 수 있습니다.',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.black87,
          ),
        );
      }
      return;
    }
    
    log('데이터 새로고침 요청');
    setState(() {
      _isWaitingForData = true;
      _isRefreshCooldown = true; // 쿨다운 시작
    });
    
    // 쿨다운 타이머 설정 (5초)
    _refreshCooldownTimer?.cancel();
    _refreshCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timer.tick >= 5) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isRefreshCooldown = false; // 쿨다운 종료
          });
          log('새로고침 쿨다운 종료');
        }
      }
    });

    final message = {
      'action': 'get',
    };

    if (_isWebSocketConnected) {
      _channel.sink.add(jsonEncode(message));
      
      // 5초 후에도 응답이 없으면 로딩 상태 유지
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _isWaitingForData) {
          setState(() {
            _isWaitingForData = false;
            // 쿨다운은 그대로 유지 (총 5초)
          });
        }
      });
    } else {
      setState(() {
        _isWaitingForData = false;
        // 쿨다운은 그대로 유지 (총 5초)
      });
      _addToMessageQueue(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 상태 로깅
    if (_selectedHole != null) {
      log('빌드 - _selectedHole: $_selectedHole, _isEditing: $_isEditing');
    }
    
    // WebSocket 연결 또는 초기화 중이거나 데이터 로딩 중일 때 공통 로딩 화면 표시
    if (!_isWebSocketInitialized || _isWaitingForData || _isInitialLoading || 
        width < 10 || height < 10 || _isAppResumed || _isReconnecting || 
        !_isWebSocketConnected || _teamMembers.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('로딩 중...', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Colors.white,
            onPressed: () {
              Navigator.pop(context);
            },
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
    final bool allScoresEntered = _selectedHole != null ? _isHoleCompleted(_selectedHole!) : false;
    log('빌드 중 확인 - _selectedHole: $_selectedHole, _isEditing: $_isEditing, allScoresEntered: $allScoresEntered');
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.event.eventTitle, style: TextStyle(color: Colors.white, fontSize: fontSizeLarge)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: appBarIconSize),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh, 
              size: appBarIconSize,
              // 쿨다운 중일 때 살짝 회색으로 표시 (완전히 비활성화하지 않음)
              color: _isWaitingForData ? Colors.grey : Colors.white.withOpacity(_isRefreshCooldown ? 0.6 : 1.0),
            ),
            onPressed: _handleRefresh, // 항상 클릭 가능
          ),
        ],
      ),
      body: Column(
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
                _buildPageIndicator(),
              ],
            ),
          ),
          if (_isEditing) _buildScoreButtonPad(),
          if (!_isEditing) ...[
            SizedBox(height: height * 0.01),
            _buildSummaryTable(_teamMembers.map((m) => m.handicapScore).toList()),
            SizedBox(height: height * 0.03),
          ],
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
            Row(
              children: [
                Expanded(
                  child: HeaderButtonContainer(
                    selectedHole: _selectedHole,
                    isEditing: _isEditing,
                    isCompleted: _isSelectedHoleCompleted,
                    allScoresEntered: _selectedHole != null ? _isHoleCompleted(_selectedHole!) : false,
                    onComplete: _selectedHole != null ? () => _completeHole(_selectedHole!) : null,
                    onEdit: _selectedHole != null ? () => _startEditingHole(_selectedHole!) : null,
                    fontSize: fontSizeLarge,
                  ),
                ),
              ],
            ),
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
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _teamMembers.map((member) {
          String shortName = _playerShortNames[member.participantId] ?? 'P?';
          return Container(
            margin: EdgeInsets.only(right: 10),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        _buildTableHeaderCell('확인'),
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
    final isHoleCompleted = _completedHoles[holeNumber] == true;
    final bool allScoresEntered = _isHoleCompleted(holeNumber);

    // log('홀 $holeNumber 상태: isCompleted=$isHoleCompleted, allScoresEntered=$allScoresEntered');

    return TableRow(
      children: [
        // 홀 번호 셀 - 완료된 홀은 체크 아이콘 표시
        Container(
          alignment: Alignment.center,
          height: cellHeight,
          color: isHoleCompleted ? Colors.green.withOpacity(0.2) : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                holeNumber.toString(),
                style: TextStyle(color: Colors.white, fontSize: fontSizeMedium),
                textAlign: TextAlign.center,
              ),
              if (isHoleCompleted)
                Icon(Icons.check_circle, color: Colors.green, size: fontSizeMedium),
            ],
          ),
        ),
        // 참가자별 점수 셀
        ..._teamMembers.map((ScoreCard member) {
          final score = _scorecard[member.participantId]?[holeIndex].score;
          final isSelected = _selectedHole == holeNumber && 
                           _selectedParticipantId == member.participantId;
          final cellColor = _getCellColor(holeNumber, member.participantId);
          
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
                    color: cellColor,
                  ) 
                : BoxDecoration(
                    color: cellColor,
                  ),
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
        // 홀 확인 버튼 셀
        Container(
          alignment: Alignment.center,
          height: cellHeight,
          color: Colors.transparent,
          child: isHoleCompleted 
            ? _buildHolButton(
                label: '수정',
                color: Colors.orange,
                onPressed: () => _startEditingHole(holeNumber),
                icon: Icons.edit,
              )
            : _buildHolButton(
                label: '확인',
                color: allScoresEntered ? Colors.green : Colors.green.withOpacity(0.3),
                onPressed: allScoresEntered ? () => _completeHole(holeNumber) : null,
                icon: Icons.check,
                isEnabled: allScoresEntered,
              ),
        ),
      ],
    );
  }

  Widget _buildHolButton({
    required String label, 
    required Color color, 
    required VoidCallback? onPressed, 
    required IconData icon,
    bool isEnabled = true,
  }) {
    return SizedBox(
      width: 70,
      height: 30,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              color: isEnabled ? Colors.white : Colors.white.withOpacity(0.5),
              size: fontSizeSmall * 1.2,
            ),
            SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.white.withOpacity(0.5),
                fontSize: fontSizeSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 점수가 실제로 입력된 적이 있는지 확인하는 메서드
  bool _hasScoreBeenEntered(int participantId, int holeIndex) {
    // 컨트롤러에 텍스트가 있거나 점수가 null이 아니면 입력된 것으로 간주
    bool hasControllerText = _controllers[participantId]?[holeIndex].text.isNotEmpty == true;
    
    // 점수가 null이 아니면 입력된 것으로 간주
    bool hasValidScore = false;
    if (_scorecard.containsKey(participantId) && 
        _scorecard[participantId]!.length > holeIndex) {
      hasValidScore = _scorecard[participantId]![holeIndex].score != null;
    }
    
    return hasControllerText || hasValidScore;
  }

  Widget _buildSummaryTable(List<int> handiScores) {
    final cellHeight = height * 0.042; // 반응형 높이 (화면 높이의 7%)
    final cellFontSize = fontSizeMedium;
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
    return Padding(
      padding: const EdgeInsets.all(4.0), // 간격 조정
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
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _currentPageIndex == index ? Colors.white : Colors.grey,
      ),
    );
  }
  void _restoreIfEmpty({required int participantId, required int holeIndex}) {
    String currentText = _controllers[participantId]?[holeIndex].text ?? "";

    // 값이 비어 있으면 원래 점수로 복원
    if (currentText.isEmpty) {
      int originalScore = _scorecard[participantId]?[holeIndex].score ?? 0;
      _controllers[participantId]?[holeIndex].text = originalScore.toString();
    }
  }

  // 셀 색상 가져오기
  Color _getCellColor(int holeNumber, int participantId) {
    String key = '${holeNumber}_$participantId';
    
    // 선택된 셀인 경우
    if (_selectedHole == holeNumber && _selectedParticipantId == participantId) {
      return Colors.blue.withOpacity(0.3);
    }
    
    // 완료된 홀인 경우 연한 녹색 배경
    if (_completedHoles[holeNumber] == true) {
      return Colors.green.withOpacity(0.2);
    }
    
    return _cellColors[key] ?? Colors.transparent; // 기본 색상
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
    // 완료된 홀인 경우 선택만 하고 편집 모드는 시작하지 않음
    if (_completedHoles[holeNumber] == true) {
      setState(() {
        _selectedHole = holeNumber;
        _selectedParticipantId = participantId;
        _isEditing = false;
        int? score = _scorecard[participantId]?[holeNumber - 1].score;
        // null(하이픈)인 경우 null로 설정
        _tempScore = score;
      });
      
      // 강제로 다시 빌드
      Future.microtask(() {
        if (mounted) setState(() {});
      });
      return;
    }
    
    setState(() {
      _selectedHole = holeNumber;
      _selectedParticipantId = participantId;
      _isEditing = true;
      int? score = _scorecard[participantId]?[holeNumber - 1].score;
      // null(하이픈)인 경우 null로 설정
      _tempScore = score;
    });
    
    // 키보드가 올라올 시간을 고려해 약간 지연 후 스크롤 조정
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _scrollToSelectedCell(holeNumber);
      }
    });
    
    // 강제로 다시 빌드
    Future.microtask(() {
      if (mounted) setState(() {});
    });
    
    // 상태 변경 후 로깅
    log('셀 선택 후: _selectedHole=$_selectedHole, _selectedParticipantId=$_selectedParticipantId, _isEditing=$_isEditing, _tempScore=$_tempScore');
  }
  
  // 선택된 셀로 스크롤하는 함수 수정
  void _scrollToSelectedCell(int holeNumber) {
    // 현재 표시된 페이지의 스크롤 컨트롤러 가져오기
    ScrollController currentScrollController = _scrollControllers[_currentPageIndex];
    
    // 테이블 셀의 대략적인 높이 계산 (셀 높이 + 경계선)
    double cellHeight = height * 0.042; // 셀 높이 추정값
    
    // 페이지 내에서의 홀 인덱스 계산 (0-based)
    int pageHoleIndex = _currentPageIndex == 0 ? holeNumber - 1 : holeNumber - 10;
    
    // 헤더와 범례를 고려한 스크롤 위치 계산
    double legendHeight = height * 0.08; // 범례 높이 추정값
    double headerHeight = cellHeight; // 헤더 높이 추정값
    double targetScroll = headerHeight + (pageHoleIndex * cellHeight);
    
    // 키보드 높이를 고려하여 스크롤 위치 조정
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    double safeAreaTop = height * 0.1; // 화면 상단에서 안전 여백
    
    // 스크롤 조정 위치 계산 - 홀이 키보드 위에 보이도록 조정
    double finalScrollPosition = targetScroll - safeAreaTop;
    
    // 음수가 되지 않도록 최소값 0으로 설정
    finalScrollPosition = finalScrollPosition < 0 ? 0 : finalScrollPosition;
    
    log('스크롤 조정: holeNumber=$holeNumber, pageIndex=$_currentPageIndex, scrollPosition=$finalScrollPosition');
    
    // 스크롤 이동
    if (currentScrollController.hasClients) {
      currentScrollController.animateTo(
        finalScrollPosition,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  // 점수 저장
  Future<void> _saveScore() async {
    if (_selectedHole == null || _selectedParticipantId == null) return;

    try {
      // 확인 응답 수신 여부 초기화
      _receivedConfirmation = false;
      _lastActionType = "post";
      _lastActionHoleNumber = _selectedHole!;
      
      log('점수 저장 응답 확인 초기화: $_receivedConfirmation');
      
      // 점수가 비어있는 경우 (null)
      if (_tempScore == null) {
        log('점수 비우기: 빈 값(하이픈)으로 저장');
        
        final message = jsonEncode({
          'action': 'post',
          'participant_id': _selectedParticipantId,
          'hole_number': _selectedHole,
          'score': null,
        });

        _channel.sink.add(message);
        _lastMessageSentTime = DateTime.now();
        
        // 응답 타임아웃 설정
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted && !_receivedConfirmation && _isWebSocketConnected) {
            log('점수 저장 응답 수신 실패 - 연결 끊김으로 간주');
            setState(() {
              _isWebSocketConnected = false;
            });
            _showReconnectDialog();
          }
        });
        
        setState(() {
          // 스코어카드에 null로 저장
          _scorecard[_selectedParticipantId]![_selectedHole! - 1] = 
            HoleScore(holeNumber: _selectedHole!, score: null);
          
          // 컨트롤러에는 빈 문자열 저장 (화면에 하이픈으로 표시)
          _controllers[_selectedParticipantId]?[_selectedHole! - 1].text = "";
          
          // 편집 상태 초기화
          _isEditing = false;
          _selectedHole = null;
          _selectedParticipantId = null;
          _tempScore = null;
        });
        return;
      }
      
      log('점수 저장: ${_tempScore}');
      
      final message = jsonEncode({
        'action': 'post',
        'participant_id': _selectedParticipantId,
        'hole_number': _selectedHole,
        'score': _tempScore,
      });

      _channel.sink.add(message);
      _lastMessageSentTime = DateTime.now();
      
      // 응답 타임아웃 설정
      Future.delayed(const Duration(seconds: 8), () {
        if (mounted && !_receivedConfirmation && _isWebSocketConnected) {
          log('점수 저장 응답 수신 실패 - 연결 끊김으로 간주');
          setState(() {
            _isWebSocketConnected = false;
          });
          _showReconnectDialog();
        }
      });
      
      setState(() {
        // 스코어카드에 점수 저장
        _scorecard[_selectedParticipantId]![_selectedHole! - 1] = 
          HoleScore(holeNumber: _selectedHole!, score: _tempScore);
        
        // 컨트롤러에 점수 저장 (모든 점수는 문자열로 저장하여 표시)
        _controllers[_selectedParticipantId]?[_selectedHole! - 1].text = _tempScore.toString();
        
        // 편집 상태 초기화
        _isEditing = false;
        _selectedHole = null;
        _selectedParticipantId = null;
        _tempScore = null;
      });
    } catch (e) {
      log('점수 저장 중 오류 발생: $e');
    }
  }

  // 점수 입력 취소
  void _cancelScoreEdit() {
    setState(() {
      _isEditing = false;
      _selectedHole = null;
      _selectedParticipantId = null;
      _tempScore = null;
    });
  }

  Widget _buildScoreButtonPad() {
    if (!_isEditing) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(width * 0.02),
      color: Colors.grey[900],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상단 버튼 영역
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 현재 선택된 점수 표시
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: height * 0.01),
                  child: Text(
                    _tempScore != null ? _tempScore.toString() : '-',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSizeLarge * 2,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              // 확인/취소 버튼
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _cancelScoreEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.04,
                        vertical: height * 0.01,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSizeMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: width * 0.02),
                  ElevatedButton(
                    onPressed: _saveScore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.04,
                        vertical: height * 0.01,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '확인',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSizeMedium,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: height * 0.01),
          // 기능 버튼 (마이너스/플러스 토글, 비우기)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // +/- 토글 버튼
              ElevatedButton(
                onPressed: () {
                  if (_tempScore != null) {
                    setState(() => _tempScore = -_tempScore!);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tempScore != null && _tempScore! < 0 ? Colors.blue : Colors.grey[800],
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                    vertical: height * 0.01,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '+/-',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSizeMedium,
                  ),
                ),
              ),
              SizedBox(width: width * 0.02),
              // 비우기 버튼
              ElevatedButton(
                onPressed: _clearScore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                    vertical: height * 0.01,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete, color: Colors.white, size: fontSizeMedium),
                    SizedBox(width: 4),
                    Text(
                      '비우기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSizeMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.01),
          // 숫자 버튼들
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: height * 0.01,
            crossAxisSpacing: width * 0.02,
            childAspectRatio: 2.5, // 버튼 높이를 더 감소
            children: [
              // 1-9 숫자 버튼
              _buildNumberButton(1),
              _buildNumberButton(2),
              _buildNumberButton(3),
              _buildNumberButton(4),
              _buildNumberButton(5),
              _buildNumberButton(6),
              _buildNumberButton(7),
              _buildNumberButton(8),
              _buildNumberButton(9),
              // 빈 버튼 (왼쪽)
              const SizedBox(),
              // 0 버튼 (중앙)
              _buildNumberButton(0),
              // 빈 버튼 (오른쪽)
              const SizedBox(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          int absValue = number;
          if (_tempScore != null && _tempScore! < 0) {
            // 음수 값을 유지
            _tempScore = -absValue;
          } else {
            _tempScore = absValue;
          }
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _tempScore != null && number == _tempScore!.abs() 
          ? Colors.blue 
          : Colors.grey[800],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        number.toString(),
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 점수 비우기 (null로 설정)
  void _clearScore() {
    setState(() {
      _tempScore = null;
    });
  }

  void _handleWebSocketError(dynamic error) {
    _isWebSocketConnected = false;
    
    // 초기 로딩 중에는 아무 동작도 하지 않음
    if (_initialConnectionAttempt || _isInitialLoading) {
      return;
    }
    
    if (error.toString().contains('too_many_connections')) {
      _showTooManyConnectionsDialog();
    } else {
      setState(() {
        _isReconnecting = true;
      });
      _showReconnectDialog();
    }
  }

  void _showConnectionStatusMessage(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.8,
          left: 10,
          right: 10,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showReconnectDialog() async {
    if (!mounted || _isReconnecting) return;

    _isReconnecting = true;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('연결 끊김'),
        content: const Text('웹소켓 연결이 끊어졌습니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // 스코어카드 페이지 나가기
            },
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }

  void _showTooManyConnectionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('접속 제한'),
        content: const Text('현재 너무 많은 접속이 있어 대기가 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // 스코어카드 페이지 나가기
            },
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }

  Future<void> _reconnectWebSocket() async {
    if (_retryCount >= MAX_RETRY_COUNT) {
      setState(() {
        _isReconnecting = false;
      });
      _showMaxRetriesExceededDialog();
      return;
    }

    try {
      _retryCount++;
      
      // 기존 연결이 있으면 닫기
      try {
        if (_channel.sink != null) {
          await _channel.sink.close();
        }
      } catch (e) {
        log('기존 WebSocket 연결 닫기 실패: $e');
      }
      
      // 이미 초기화된 웹소켓이 있으면 재사용
      if (_isWebSocketInitialized) {
        log('이미 초기화된 WebSocket 재사용');
        // 기존 연결 상태 초기화
        setState(() {
          _isWebSocketConnected = false;
          _isWaitingForData = false;
        });
        
        // 기존 스트림 리스너 제거
        _channel.stream.listen(null).cancel();
        
        // 새로운 리스너 등록
        _channel.stream.listen(
          (data) {
            if (!mounted) return;
            _handleWebSocketData(data);
          },
          onError: (error) {
            log('WebSocket 오류 발생: $error');
            _handleWebSocketError(error);
          },
          onDone: () {
            log('WebSocket 연결 종료');
            if (mounted) {
              _showReconnectDialog();
            }
          },
        );
        
        // 연결 상태 확인을 위한 데이터 요청
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) {
                _handleRefresh();
              }
            });
      } else {
        // 초기화되지 않은 경우 새로 초기화
        await _initWebSocket();
      }
      
      // 재연결 성공 시 타이머 설정
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
        if (!_isWebSocketConnected && mounted) {
          _reconnectWebSocket();
        }
      });
    } catch (e) {
      log('WebSocket 재연결 실패: $e');
      setState(() {
        _isReconnecting = false;
      });
      _showReconnectDialog();
    }
  }

  void _showMaxRetriesExceededDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('재연결 실패'),
        content: const Text('최대 재시도 횟수를 초과했습니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // 스코어카드 페이지 나가기
            },
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }

  // 메시지 큐 처리 및 타임아웃 로직 추가
  void _addToMessageQueue(Map<String, dynamic> message) {
    _messageQueue.add(message);
    _lastMessageSentTime = DateTime.now();
    
    if (_isWebSocketConnected) {
      _processQueuedMessages();
    } else {
      // 메시지 큐 처리 타임아웃 설정
      Future.delayed(const Duration(seconds: 10), () {
        if (_messageQueue.isNotEmpty && _lastMessageSentTime != null) {
          if (DateTime.now().difference(_lastMessageSentTime!).inSeconds > 10) {
            log('메시지 큐 처리 타임아웃 - 연결 끊김으로 간주');
            _showReconnectDialog();
          }
        }
      });
    }
  }

  void _processQueuedMessages() {
    while (_messageQueue.isNotEmpty && _isWebSocketConnected) {
      final message = _messageQueue.removeFirst();
      _channel.sink.add(jsonEncode(message));
    }
  }

  void _showScoreSummary() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OverallScorePage(event: widget.event)),
    );
  }

  // 플레이어 약어 이름 초기화 메서드 추가
  void _initPlayerShortNames() {
    for (int i = 0; i < _myGroupParticipants.length; i++) {
      int participantId = _myGroupParticipants[i].participantId;
      _playerShortNames[participantId] = 'P${i + 1}';
    }
  }

  // 특정 홀에 대해 모든 팀원이 점수를 입력했는지 확인
  bool _isHoleCompleted(int holeNumber) {
    // 홀 인덱스 계산 (0-based)
    int holeIndex = holeNumber - 1;
    
    // log('_isHoleCompleted 호출: holeNumber=$holeNumber, teamMembers=${_teamMembers.length}');
    
    // 팀원이 없는 경우 (혼자인 경우) 내 점수가 입력되었는지 확인
    if (_teamMembers.isEmpty) {
      // log('팀원 없음, 자신의 점수만 확인');
      return _hasScoreBeenEntered(_myParticipantId, holeIndex);
    }
    
    // 팀원이 한 명뿐인 경우 (나 자신)
    if (_teamMembers.length == 1) {
      int participantId = _teamMembers[0].participantId;
      bool hasScore = _hasScoreBeenEntered(participantId, holeIndex);
      //log('팀원 한 명: ${_teamMembers[0].userName}(ID: $participantId) 점수 입력 여부: $hasScore');
      return hasScore;
    }
    
    // 모든 팀원에 대해 점수가 입력되었는지 확인
    for (var member in _teamMembers) {
      int participantId = member.participantId;
      bool hasScore = _hasScoreBeenEntered(participantId, holeIndex);
      // log('팀원 ${member.userName}(ID: $participantId) 점수 입력 여부: $hasScore');
      
      // 점수가 입력되지 않은 팀원이 있으면 false 반환
      if (!hasScore) {
        return false;
      }
    }
    
    // 모든 팀원이 점수를 입력했으면 true 반환
    // log('모든 팀원이 점수 입력 완료');
    return true;
  }
  
  // 홀 완료 상태 변경
  void _completeHole(int holeNumber) {
    if (!_isWebSocketConnected) {
      _showReconnectDialog();
      return;
    }

    // 확인 응답 수신 여부 초기화
    _receivedConfirmation = false;
    _lastActionType = "confirm_hole";
    _lastActionHoleNumber = holeNumber;
    
    log('홀 완료 응답 확인 초기화: $_receivedConfirmation, 홀: $holeNumber');

    final message = {
      'action': 'confirm_hole',
      'participant_id': _myParticipantId,
      'hole_number': holeNumber,
      'type': 'confirm_hole',
    };

    _channel.sink.add(jsonEncode(message));
    _lastMessageSentTime = DateTime.now();
    
    // 응답 타임아웃 설정
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && !_receivedConfirmation && _isWebSocketConnected) {
        log('홀 완료 응답 수신 실패 - 연결 끊김으로 간주');
        setState(() {
          _isWebSocketConnected = false;
        });
        _showReconnectDialog();
      }
    });
    
    // 로컬 상태는 웹소켓 응답을 받은 후 _handleWebSocketData에서 업데이트
    setState(() {
      _isEditing = false;
      _selectedHole = null;
      _selectedParticipantId = null;
      _tempScore = null;
    });
  }
  
  // 홀 수정 모드 시작 로직 수정
  void _startEditingHole(int holeNumber) {

    // 확인 응답 수신 여부 초기화
    _receivedConfirmation = false;
    _lastActionType = "uncheck_hole";
    _lastActionHoleNumber = holeNumber;
    
    log('홀 수정 응답 확인 초기화: $_receivedConfirmation, 홀: $holeNumber');

    final message = {
      'action': 'uncheck_hole',
      'hole_number': holeNumber,
      'type': 'uncheck_hole',
    };

    _channel.sink.add(jsonEncode(message));
    _lastMessageSentTime = DateTime.now();
    
    // 응답 타임아웃 설정
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && !_receivedConfirmation && _isWebSocketConnected) {
        log('홀 수정 응답 수신 실패 - 연결 끊김으로 간주');
        setState(() {
          _isWebSocketConnected = false;
        });
        _showReconnectDialog();
      }
    });
    
    // 로컬 상태는 웹소켓 응답을 받은 후 _handleWebSocketData에서 업데이트
  }

  // 웹소켓 연결 상태 확인
  void _checkConnectionStatus() {
    if (!_isWebSocketConnected) return;
    
    // 응답 수신 여부 초기화
    _receivedCheckResponse = false;
    
    // get 메시지 전송 (ping 대신)
    final checkMessage = {
      'action': 'get',
    };
    
    log('WebSocket 연결 상태 확인 중...');
    _channel.sink.add(jsonEncode(checkMessage));
    _lastMessageSentTime = DateTime.now();
    
    // 응답 타임아웃 설정
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_receivedCheckResponse && _isWebSocketConnected) {
        log('연결 확인 응답 수신 실패 - 연결 끊김으로 간주');
        setState(() {
          _isWebSocketConnected = false;
        });
        _showReconnectDialog();
      }
    });
  }

  // 로딩 타임아웃 타이머 시작
  void _startLoadingTimeoutTimer() {
    // 기존 타이머가 있으면 취소
    _loadingTimeoutTimer?.cancel();
    
    // 5초 후에 로딩 상태 확인
    _loadingTimeoutTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        if (!_isWebSocketInitialized || _isInitialLoading || _isWaitingForData) {
          // 웹소켓 연결 문제 또는 데이터 로딩 문제 모두 연결 재시도로 처리
          log('로딩 타임아웃 - 웹소켓 연결 재시도 필요');
          _showConnectionFailDialog();
        }
      }
    });
  }
  
  // 연결 실패 다이얼로그 (통합)
  void _showConnectionFailDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('연결 실패'),
        content: const Text('서버와의 연결에 문제가 발생했습니다. 네트워크 연결을 확인하고 다시 시도해주세요.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              Navigator.of(context).pop(); // 스코어카드 페이지 나가기
            },
            child: const Text('이전 화면으로'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              
              // 웹소켓 다시 초기화 전에 잠시 지연 - 네트워크 연결 시간 확보
              setState(() {
                _isInitialLoading = true;
                _isWaitingForData = false;
              });
              
              // 재연결 상태 초기화 - 새로운 연결 시도 허용
              _isReconnecting = false;
              
              // 약간의 지연 후 연결 시도 (1.5초)
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) {
                  _initWebSocket();
                  
                  // 첫 번째 시도가 실패하면 추가 시도
                  Future.delayed(const Duration(seconds: 5), () {
                    if (mounted && !_isWebSocketConnected) {
                      log('첫 번째 연결 시도 실패 - 자동으로 재시도');
                      _initWebSocket();
                    }
                  });
                }
                
                _startLoadingTimeoutTimer(); // 타임아웃 타이머 재시작
              });
            },
            child: const Text('다시 연결'),
          ),
        ],
      ),
    );
  }
}

// 헤더 버튼 전용 StatefulWidget
class HeaderButtonContainer extends StatefulWidget {
  final int? selectedHole;
  final bool isEditing;
  final bool isCompleted;
  final bool allScoresEntered;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final double fontSize;

  const HeaderButtonContainer({
    Key? key,
    required this.selectedHole,
    required this.isEditing,
    required this.isCompleted,
    required this.allScoresEntered,
    required this.onComplete,
    required this.onEdit,
    required this.fontSize,
  }) : super(key: key);

  @override
  State<HeaderButtonContainer> createState() => _HeaderButtonContainerState();
}

class _HeaderButtonContainerState extends State<HeaderButtonContainer> {
  @override
  Widget build(BuildContext context) {
    // 수정 중인 경우에도 전체 현황 조회 버튼 표시
    if (widget.isEditing) {
      log('편집 중 -> 전체 현황 조회 버튼 표시');
      return const SizedBox.shrink();
    }
    
    // 선택된 홀이 없으면 전체 현황 조회 버튼만 표시
    if (widget.selectedHole == null) {
      log('홀 선택 안됨 -> 전체 현황 조회 버튼 표시');
      return const SizedBox.shrink();
    }
    
    log('헤더 버튼 렌더링: selectedHole=${widget.selectedHole}, isEditing=${widget.isEditing}, isCompleted=${widget.isCompleted}');
    
    // 선택된 홀이 있고 그 홀이 완료된 상태인 경우 빈 공간 표시
    if (widget.isCompleted) {
      log('완료된 홀 선택됨 -> 빈 공간 표시');
      return const SizedBox.shrink();
    }
    
    // 홀 완료 버튼 표시 (모든 점수가 입력된 경우에만 활성화)
    log('일반 홀 선택됨 -> 홀 완료 버튼 표시(활성화: ${widget.allScoresEntered})');
    return ElevatedButton(
      onPressed: widget.allScoresEntered ? widget.onComplete : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        disabledBackgroundColor: Colors.green.withOpacity(0.3),
        disabledForegroundColor: Colors.white.withOpacity(0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check, color: widget.allScoresEntered ? Colors.white : Colors.white.withOpacity(0.5)),
          const SizedBox(width: 8),
          Text(
            '홀 완료',
            style: TextStyle(
              color: widget.allScoresEntered ? Colors.white : Colors.white.withOpacity(0.5),
              fontSize: widget.fontSize
            )
          ),
        ],
      ),
    );
  }
}