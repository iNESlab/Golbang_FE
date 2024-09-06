import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:golbang/pages/game/overall_score_page.dart';

void main() {
  runApp(MaterialApp(
    home: ScoreCardPage(),
  ));
}

class ScoreCardPage extends StatefulWidget {
  @override
  _ScoreCardPageState createState() => _ScoreCardPageState();
}

class _ScoreCardPageState extends State<ScoreCardPage> {
  int _currentPageIndex = 0;

  final List<String> _teamMembers = ['고동범', '김민정', '박재윤', '정수미'];
  final List<List<String>> _scores = List.generate(18, (_) => List.generate(4, (_) => ''));
  final List<int> _handicaps = [2, 3, 1, 4]; // 각 선수의 핸디캡 설정

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
          _buildSummaryTable(), // 페이지 넘김 없이 고정된 스코어 요약 표
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
        for (String member in _teamMembers) _buildTableHeaderCell(member),
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
        for (int i = 0; i < _teamMembers.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2.0),
            child: Center(
              child: TextFormField(
                initialValue: _scores[holeIndex][i],
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // 숫자만 입력 가능하도록 설정
                onChanged: (value) {
                  _updateScore(holeIndex, i, value);
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

  Widget _buildSummaryTable() {
    List<int> frontNine = _calculateFrontNineScores();
    List<int> backNine = _calculateBackNineScores();
    List<int> totalScores = _calculateTotalScores();
    List<int> handicapScores = _calculateHandicapScores(totalScores);

    return Container(
      color: Colors.black,
      padding: EdgeInsets.all(16.0),
      child: Table(
        border: TableBorder.all(color: Colors.grey),
        children: [
          _buildSummaryTableRow(['', ..._teamMembers]),
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
      int sum = 0;
      for (int j = 0; j < 9; j++) {
        sum += int.tryParse(_scores[j][i]) ?? 0;
      }
      return sum;
    });
  }

  List<int> _calculateBackNineScores() {
    return List.generate(_teamMembers.length, (i) {
      int sum = 0;
      for (int j = 9; j < 18; j++) {
        sum += int.tryParse(_scores[j][i]) ?? 0;
      }
      return sum;
    });
  }

  List<int> _calculateTotalScores() {
    return List.generate(_teamMembers.length, (i) {
      return _calculateFrontNineScores()[i] + _calculateBackNineScores()[i];
    });
  }

  List<int> _calculateHandicapScores(List<int> totalScores) {
    return List.generate(_teamMembers.length, (i) {
      return totalScores[i] - _handicaps[i];
    });
  }

  void _updateScore(int holeIndex, int playerIndex, String value) {
    setState(() {
      _scores[holeIndex][playerIndex] = value;
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
