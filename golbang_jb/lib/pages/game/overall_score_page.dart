import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../models/socket/rank.dart';
import '../../repoisitory/secure_storage.dart';

class OverallScorePage extends ConsumerStatefulWidget {
  final int participantId;

  const OverallScorePage({
    super.key,
    required this.participantId,
  });

  @override
  _OverallScorePageState createState() => _OverallScorePageState();

}

class _OverallScorePageState extends ConsumerState<OverallScorePage> {
  late final WebSocketChannel _channel;
  List<Rank> _players = [];
  bool _handicapOn = false; // 핸디캡 버튼 상태

  @override
  void initState() {
    super.initState();
    _initWebSocket();
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
      Uri.parse('${dotenv.env['WS_HOST']}/participants/${widget.participantId}/event/stroke'),
      headers: {
        'Authorization': 'Bearer $accessToken', // 토큰을 헤더에 포함
      },// 실제 WebSocket 서버 주소로 변경
    );

    // WebSocket 데이터 수신 처리
    _channel.stream.listen((data) {
      print('WebSocket 데이터 수신: $data');
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

    setState(() {
      // 수신된 데이터를 Rank 객체로 변환하여 _players 리스트에 저장
      _players = rankingsJson.map((json) => Rank.fromJson(json)).toList();
    });
  }

  String _getPlayerRank() {
    final player = _players.firstWhere(
          (p) => p.participantId == widget.participantId,
    );
    if (_handicapOn)
      return player.handicapRank;
    else
      return player.rank;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '제 18회 iNES 골프대전 - 전체 현황',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: _players.length,
              itemBuilder: (context, index) {
                return _buildPlayerItem(_players[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      color: Colors.black,
      child: Row(
        children: [
          Image.asset(
            'assets/images/google.png', // 로고 이미지
            height: 40,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2024.03.18',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                      ),
                      child: Text('스코어카드 가기'),
                    ),
                    SizedBox(width: 8),
                    _buildRankIndicator('My Rank', _getPlayerRank(), Colors.red),
                    SizedBox(width: 8),
                    _buildHandicapToggle(),
                  ],
                ),
              ],
            ),
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

  Widget _buildHandicapToggle() {
    return Row(
      children: [
        Text(
          'Handicap',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        Switch(
          value: _handicapOn,
          onChanged: (value) {
            setState(() async {
              _handicapOn = value;
              if(_handicapOn)
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

  Widget _buildPlayerItem(Rank player) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
      child: Container(
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              // backgroundImage: NetworkImage(),
              backgroundImage: player.profileImage.startsWith('http')
                  ? NetworkImage(player.profileImage)
                  : AssetImage(player.profileImage) as ImageProvider,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${player.rank ?? ''} ${player.userName}',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    '${player.lastHoleNumber}홀',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
            if (player.participantId == widget.participantId)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Me',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            Spacer(),
            Text(
              '+${player.lastScore} (${player.sumScore})',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
