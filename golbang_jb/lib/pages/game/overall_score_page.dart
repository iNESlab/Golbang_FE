import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/models/profile/club_profile.dart';
import 'package:golbang/utils/reponsive_utils.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../models/event.dart';
import '../../models/socket/rank.dart';
import '../../repoisitory/secure_storage.dart';
import '../../widgets/common/circular_default_person_icon.dart';

class OverallScorePage extends ConsumerStatefulWidget {
  final Event event;

  const OverallScorePage({
    super.key,
    required this.event,
  });

  @override
  _OverallScorePageState createState() => _OverallScorePageState();

}

class _OverallScorePageState extends ConsumerState<OverallScorePage> {
  late final WebSocketChannel _channel;
  List<Rank> _players = [];
  bool _handicapOn = false; // 핸디캡 버튼 상태
  late final int _myParticipantId;
  late final ClubProfile _clubProfile;
  late double screenWidth = MediaQuery.of(context).size.width; // 화면 너비
  late double screenHeight = MediaQuery.of(context).size.height; // 화면 높이
  late Orientation orientation = MediaQuery.of(context).orientation;
  late double fontSizeLarge = ResponsiveUtils.getLargeFontSize(screenWidth, orientation); // 너비의 4%를 폰트 크기로 사용
  late double fontSizeMedium = ResponsiveUtils.getMediumFontSize(screenWidth, orientation);
  late double fontSizeSmall = ResponsiveUtils.getSmallFontSize(screenWidth, orientation); // 너비의 3%를 폰트 크기로 사용
  late double appBarIconSize = ResponsiveUtils.getAppBarIconSize(screenWidth, orientation);
  late double avatarSize = fontSizeMedium * 2;
  final GlobalKey _infoKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initWebSocket();
    _myParticipantId = widget.event.myParticipantId;
    _clubProfile = widget.event.club!;
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  // WebSocket 연결 설정
  Future<void> _initWebSocket() async {
    SecureStorage secureStorage = ref.read(secureStorageProvider);
    final accessToken = await secureStorage.readAccessToken();
    _channel = IOWebSocketChannel.connect(
      Uri.parse('${dotenv
          .env['WS_HOST']}/participants/$_myParticipantId/event/stroke'),
      headers: {
        'Authorization': 'Bearer $accessToken', // 토큰을 헤더에 포함
      }, // 실제 WebSocket 서버 주소로 변경
    );

    // WebSocket 데이터 수신 처리
    _channel.stream.listen((data) {
      log('WebSocket 데이터 수신');
      _handleWebSocketData(data);
    }, onError: (error) {
      log('WebSocket 오류 발생: $error');
    }, onDone: () {
      log('WebSocket 연결 종료');
    });
  }

  // WebSocket으로 수신된 데이터를 처리하는 함수
  void _handleWebSocketData(String data) {
    var parsedData = jsonDecode(data);
    List<dynamic> rankingsJson = parsedData['rankings'];

    if (rankingsJson.isNotEmpty) {
      setState(() {
        // 수신된 데이터를 Rank 객체로 변환하여 _players 리스트에 저장
        _players = rankingsJson.map((json) => Rank.fromJson(json)).toList();
        for (var p in _players) {
          log('_player: ${p.userName}, ${p.profileImage}');
        }
      });
    }
  }

  String _getMyRank() {
    Rank? player;
    try {
      player = _players.firstWhere(
            (p) => p.participantId == _myParticipantId,
      );
    } catch (e) {
      player = null; // 참가자가 없을 경우 null을 할당
    } // _players가 비어있는 경우 null 반환

    log('player: $player');

    // 참가자가 없으면 '-' 반환
    if (player == null) {
      return 'N/A';
    } else if (_handicapOn) {
      return player.handicapRank;
    } else {
      return player.rank;
    }
  }

  // 서버에 새로고침 요청을 보내는 함수
  Future<void> _changeSort(String sort) async {
    final message = jsonEncode({
      'sort': sort,
    });

    // WebSocket을 통해 새로고침 요청 전송
    _channel.sink.add(message);
    log('Score 전송: $message');

    // 약간의 지연시간을 추가하여 새로고침 완료 시각적으로 표시
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery
        .of(context)
        .size
        .width;
    final height = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.event.eventTitle} - 전체 현황',
          style: TextStyle(
              color: Colors.white, fontSize: fontSizeLarge), // 반응형 폰트 크기
        ),
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
            icon: Icon(Icons.refresh, size: appBarIconSize),
            color: Colors.white,
            onPressed: () async {
              await _changeSort(_handicapOn ? 'handicap_score' : 'sum_score');
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _players.isEmpty
          ? Center(
        child: Text(
          '스코어를 기록한 참가자가 없습니다.',
          style: TextStyle(
              color: Colors.white, fontSize: fontSizeLarge), // 반응형 폰트 크기
        ),
      )
          : Column(
        children: [
          _buildHeader(width, height),
          _buildScoreInfoPopup(width, height),
          Expanded(
            child: ListView.builder(
              itemCount: _players.length,
              itemBuilder: (context, index) {
                return _buildPlayerItem(_players[index], width, height);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formattedDate(DateTime dateTime) {
    return dateTime.toIso8601String().split('T').first; // T 문자로 나누고 첫 번째 부분만 가져옴
  }
  Widget _buildScoreInfoPopup(double width, double height){
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.005),
      child: GestureDetector(
        key: _infoKey, // 위치 계산을 위해 GlobalKey 사용
        onTap: () {
          // info 버튼의 RenderBox와 offset, size 계산
          final RenderBox renderBox = _infoKey.currentContext!.findRenderObject() as RenderBox;
          final Offset offset = renderBox.localToGlobal(Offset.zero);
          final Size size = renderBox.size;

          // 팝업을 버튼 오른쪽 아래에 표시
          final RelativeRect position = RelativeRect.fromLTRB(
            offset.dx + size.width,       // 버튼 오른쪽으로 약간 이동
            offset.dy + size.height + 10,      // 버튼 아래쪽으로 이동
            0,                            // 오른쪽 여백은 0으로
            0,                            // 아래 여백은 0으로
          );

          showMenu(
            context: context,
            position: position,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: Colors.white, // 흰색 배경
            items: [
              PopupMenuItem(
                enabled: false,  // 클릭 불가
                child: SizedBox(
                  width: width * 0.45,    // 필요 시 팝업 너비 지정 (원하는 대로 조절)
                  child: Text(
                    '골프 스코어는 두 가지 숫자로 표기됩니다.\n\n'
                    '예) "+1 (14)"\n'
                    '• "+1": 방금 친 홀에서 기록한 점수\n'
                    '• "(14)": 지금까지의 누적 스코어\n\n'
                    '즉, 괄호 안의 숫자가 전체 합계 점수이며, 앞쪽의 숫자는 마지막 홀에서 친 점수를 의미합니다.',
                    style: TextStyle(
                      fontSize: fontSizeSmall,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '점수 표기 안내',
              style: TextStyle(fontSize: fontSizeSmall, color: Colors.white),
            ),
            const SizedBox(width: 4),
            Icon(Icons.info_outline, size: fontSizeSmall + 2, color: Colors.white),
          ],
        ),
      ),
    );
  }
  Widget _buildHeader(double width, double height) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: height * 0.02, // 반응형 상하 패딩
        horizontal: width * 0.03, // 반응형 좌우 패딩
      ),
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 요소 간 간격 균등 배분
        crossAxisAlignment: CrossAxisAlignment.center, // 수직 중앙 정렬
        children: [
          // 아바타와 클럽 이름
          Expanded(
            flex: 2, // 비율 조정
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: avatarSize,
                  backgroundImage: _clubProfile.image.startsWith('https')
                      ? NetworkImage(_clubProfile.image)
                      : AssetImage(_clubProfile.image) as ImageProvider,
                  backgroundColor: Colors.transparent, // 배경을 투명색으로 설정
                ),
                SizedBox(height: height * 0.01), // 반응형 간격
                Text(
                  widget.event.club!.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSizeLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // 날짜와 버튼
          Expanded(
            flex: 2, // 비율 조정
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _formattedDate(widget.event.startDateTime),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSizeMedium,
                  ),
                ),
                SizedBox(height: height * 0.01),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: height * 0.01,
                      horizontal: width * 0.03,
                    ), // 반응형 버튼 패딩
                  ),
                  child: Text(
                    '스코어카드 가기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: fontSizeSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 랭크 표시와 토글
          Expanded(
            flex: 3, // 비율 조정
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 요소 간 간격 균등
              children: [
                _buildRankIndicator(
                  'My Rank',
                  _getMyRank(),
                  Colors.red,
                  width,
                  height,
                ),
                _buildHandicapToggle(width, height),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankIndicator(String title, String value, Color color,
      double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.03), // 반응형 패딩
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(width * 0.02), // 반응형 모서리 반경
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
                color: Colors.white, fontSize: fontSizeMedium), // 반응형 폰트 크기
          ),
          Text(
            value,
            style: TextStyle(
                color: Colors.white, fontSize: fontSizeLarge), // 반응형 폰트 크기
          ),
        ],
      ),
    );
  }

  Widget _buildHandicapToggle(double width, double height) {
    return Column(
      children: [
        Text(
          'Handicap',
          style: TextStyle(
              color: Colors.white, fontSize: fontSizeMedium), // 반응형 폰트 크기
        ),
        Switch(
          value: _handicapOn,
          onChanged: (value) {
            setState(() async {
              _handicapOn = value;
              if (_handicapOn) {
                await _changeSort('handicap_score');
              } else {
                await _changeSort('sum_score');
              }
            });
          },
          activeColor: Colors.cyan,
        ),
      ],
    );
  }

  Widget _buildPlayerItem(Rank player, double width, double height) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: height * 0.01, // 반응형 상하 패딩
        horizontal: width * 0.03, // 반응형 좌우 패딩
      ),
      child: Container(
        padding: EdgeInsets.all(width * 0.02), // 반응형 내부 패딩
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(width * 0.03), // 반응형 모서리 반경
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: avatarSize, // 반응형 아바타 크기
              backgroundColor: Colors.grey[300], // 배경색 (선택사항)
              child: player.profileImage != null
                  ? ClipOval(
                child: Image.network(
                  player.profileImage!,
                  width: avatarSize * 2,
                  height: avatarSize * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return CircularIcon(containerSize: avatarSize * 2); // 네트워크 이미지 로딩 실패 시 아이콘 표시
                  },
                ),
              )
                  : CircularIcon(containerSize: avatarSize * 2), // 이미지가 http가 아니면 동그란 아이콘 표시
            ),
            SizedBox(width: width * 0.03), // 반응형 간격
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_handicapOn ? player.handicapRank : player.rank} ${player
                        .userName}',
                    style: TextStyle(color: Colors.white,
                        fontSize: fontSizeLarge), // 반응형 폰트 크기
                  ),
                  Text(
                    '${player.lastHoleNumber}홀',
                    style: TextStyle(color: Colors.white54,
                        fontSize: fontSizeMedium), // 반응형 폰트 크기
                  ),
                ],
              ),
            ),
            if (player.participantId == _myParticipantId)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.02,
                  vertical: height * 0.01,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(width * 0.02),
                ),
                child: Text(
                  'Me',
                  style: TextStyle(
                      color: Colors.white, fontSize: fontSizeMedium), // 반응형 폰트 크기
                ),
              ),
            const Spacer(),
            Text(
              '${player.lastScore > 0 ? '+${player.lastScore}' : player
                  .lastScore} (${_handicapOn ? player.handicapScore : player
                  .sumScore})',
              style: TextStyle(
                  color: Colors.white, fontSize: fontSizeLarge), // 반응형 폰트 크기
            ),
          ],
        ),
      ),
    );
  }
}
