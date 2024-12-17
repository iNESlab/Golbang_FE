import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/models/profile/club_profile.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../models/event.dart';
import '../../models/socket/rank.dart';
import '../../repoisitory/secure_storage.dart';

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
          .env['WS_HOST']}/participants/${_myParticipantId}/event/stroke'),
      headers: {
        'Authorization': 'Bearer $accessToken', // 토큰을 헤더에 포함
      }, // 실제 WebSocket 서버 주소로 변경
    );

    // WebSocket 데이터 수신 처리
    _channel.stream.listen((data) {
      print('WebSocket 데이터 수신');
      _handleWebSocketData(data);
    }, onError: (error) {
      print('WebSocket 오류 발생: $error');
    }, onDone: () {
      print('WebSocket 연결 종료');
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
        for (var p in _players)
          print('_players: $p');
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

    print('player: $player');

    // 참가자가 없으면 '-' 반환
    if (player == null)
      return 'N/A';
    // 핸디캡 여부에 따라 랭크 반환
    else if (_handicapOn) {
      return player.handicapRank;
    } else {
      return player.rank;
    }
  }

  // 서버에 새로고침 요청을 보내는 함수
  Future<void> _changeSort(String sort) async {
    final message = jsonEncode({
      'sort': '$sort',
    });

    // WebSocket을 통해 새로고침 요청 전송
    _channel.sink.add(message);
    print('Score 전송: $message');

    // 약간의 지연시간을 추가하여 새로고침 완료 시각적으로 표시
    await Future.delayed(Duration(seconds: 1));
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
              color: Colors.white, fontSize: width * 0.05), // 반응형 폰트 크기
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
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
              color: Colors.white, fontSize: width * 0.04), // 반응형 폰트 크기
        ),
      )
          : Column(
        children: [
          _buildHeader(width, height),
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
                  radius: width * 0.06, // 반응형 아바타 크기
                  backgroundImage: _clubProfile.image.startsWith('http')
                      ? NetworkImage(_clubProfile.image)
                      : AssetImage(_clubProfile.image) as ImageProvider,
                ),
                SizedBox(height: height * 0.01), // 반응형 간격
                Text(
                  '${widget.event.club!.name}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.035,
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
                  '${_formattedDate(widget.event.startDateTime)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.035,
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
                      fontSize: width * 0.03,
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
                color: Colors.white, fontSize: width * 0.03), // 반응형 폰트 크기
          ),
          Text(
            value,
            style: TextStyle(
                color: Colors.white, fontSize: width * 0.035), // 반응형 폰트 크기
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
              color: Colors.white, fontSize: width * 0.03), // 반응형 폰트 크기
        ),
        Switch(
          value: _handicapOn,
          onChanged: (value) {
            setState(() async {
              _handicapOn = value;
              if (_handicapOn)
                await _changeSort('handicap_score');
              else
                await _changeSort('sum_score');
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
              radius: width * 0.05, // 반응형 아바타 크기
              backgroundColor: Colors.grey[300], // 배경색 (선택사항)
              child: player.profileImage.startsWith('http')
                  ? ClipOval(
                child: Image.network(
                  player.profileImage,
                  width: width * 0.1,
                  height: width * 0.1,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildCircularIcon(width); // 네트워크 이미지 로딩 실패 시 아이콘 표시
                  },
                ),
              )
                  : _buildCircularIcon(width), // 이미지가 http가 아니면 동그란 아이콘 표시
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
                        fontSize: width * 0.04), // 반응형 폰트 크기
                  ),
                  Text(
                    '${player.lastHoleNumber}홀',
                    style: TextStyle(color: Colors.white54,
                        fontSize: width * 0.035), // 반응형 폰트 크기
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
                      color: Colors.white, fontSize: width * 0.03), // 반응형 폰트 크기
                ),
              ),
            Spacer(),
            Text(
              '${player.lastScore > 0 ? '+${player.lastScore}' : player
                  .lastScore} (${_handicapOn ? player.handicapScore : player
                  .sumScore})',
              style: TextStyle(
                  color: Colors.white, fontSize: width * 0.035), // 반응형 폰트 크기
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildCircularIcon(double width) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[300], // 배경색
        shape: BoxShape.circle,  // 원형 설정
      ),
      child: Icon(
        Icons.person,
        size: width * 0.1 * 0.6,
        color: Colors.grey,
      ),
    );
  }
}
