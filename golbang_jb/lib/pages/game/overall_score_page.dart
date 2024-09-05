import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: OverallScorePage(),
  ));
}

class OverallScorePage extends StatefulWidget {
  @override
  _OverallScorePageState createState() => _OverallScorePageState();
}

class _OverallScorePageState extends State<OverallScorePage> {
  // 새로운 데이터 구조에 맞춘 참가자 데이터
  final List<Map<String, dynamic>> _players = [
    {
      "user": {"name": "고동범"},
      "participant_id": 1,
      "last_hole_number": 17,
      "last_score": 6,
      "rank": 1,
      "handicap_rank": null,
      "sum_score": 77,
      "handicap_score": 0,
      "profileImage": 'assets/images/google.png'
    },
    {
      "user": {"name": "김민정"},
      "participant_id": 2,
      "last_hole_number": 17,
      "last_score": 9,
      "rank": 2,
      "handicap_rank": null,
      "sum_score": 81,
      "handicap_score": 0,
      "profileImage": 'assets/images/google.png'
    },
    {
      "user": {"name": "김동림"},
      "participant_id": 3,
      "last_hole_number": 17,
      "last_score": 10,
      "rank": 3,
      "handicap_rank": null,
      "sum_score": 85,
      "handicap_score": 0,
      "profileImage": 'assets/images/google.png'
    },
    {
      "user": {"name": "박재윤"},
      "participant_id": 4,
      "last_hole_number": 17,
      "last_score": 13,
      "rank": 4,
      "handicap_rank": 4,
      "sum_score": 87,
      "handicap_score": 0,
      "profileImage": 'assets/images/google.png',
      "isMe": true,
    },
    {
      "user": {"name": "정수미"},
      "participant_id": 5,
      "last_hole_number": 17,
      "last_score": 13,
      "rank": 4,
      "handicap_rank": null,
      "sum_score": 87,
      "handicap_score": 0,
      "profileImage": 'assets/images/google.png'
    },
    {
      "user": {"name": "박하준"},
      "participant_id": 6,
      "last_hole_number": 18,
      "last_score": 15,
      "rank": 6,
      "handicap_rank": null,
      "sum_score": 90,
      "handicap_score": 0,
      "profileImage": 'assets/images/google.png'
    },
    // 추가 참가자 데이터...
  ];

  bool _handicapOn = false; // 핸디캡 버튼 상태

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '제 18회 iNES 골프대전 - 전체 현황',
          style: TextStyle(color: Colors.white), // 타이틀 글자 색상 수정
        ),
        backgroundColor: Colors.black,
        leading: IconButton( // 뒤로 가기 버튼 추가
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
                    _buildRankIndicator('My Rank', 'T6 +13', Colors.red),
                    SizedBox(width: 8),
                    _buildHandicapToggle(), // 핸디캡 토글 버튼 추가
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
            setState(() {
              _handicapOn = value;
            });
          },
          activeColor: Colors.cyan,
        ),
      ],
    );
  }

  Widget _buildPlayerItem(Map<String, dynamic> player) {
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
              backgroundImage: AssetImage(player['profileImage']),
              radius: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${player['rank'] != null ? player['rank'].toString() : ''} ${player['user']['name']}',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    '${player['last_hole_number']}홀',
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
            if (player['isMe'] ?? false)
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
              '+${player['last_score']} (${player['sum_score']})',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
