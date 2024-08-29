import 'package:flutter/material.dart';
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ScoreCardPage(),
    );
  }
}

class ScoreCardPage extends StatefulWidget {
  @override
  _ScoreCardPageState createState() => _ScoreCardPageState();
}

class _ScoreCardPageState extends State<ScoreCardPage> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Icon(Icons.arrow_back, color: Colors.white),
        title: Text(
          '제 18회 iNES 골프대전',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/golf_icon.png',
                          height: 50,
                        ),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '2024.03.18',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            Text(
                              '스트로크, 개인전',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        '전체 현황 조회',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Column(
                  children: [
                    RankHandicapCard(title: 'Rank', value: '2', player: '고종범', color: Colors.red),
                    SizedBox(height: 8),
                    RankHandicapCard(title: 'Handicap', value: '-3', player: '고종범', color: Colors.teal),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: PageView(
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildScoreTablePage(start: 1, end: 9),
                _buildScoreTablePage(start: 10, end: 18),
              ],
            ),
          ),
          SizedBox(height: 10),
          DotsIndicator(dotsCount: 2, position: _currentPage),
        ],
      ),
    );
  }

  Widget _buildScoreTablePage({required int start, required int end}) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Table(
            border: TableBorder.all(color: Colors.grey.shade800),
            columnWidths: {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                children: [
                  _buildTableCell('홀'),
                  _buildTableCell('고종범'),
                  _buildTableCell('김민정'),
                  _buildTableCell('박재윤'),
                  _buildTableCell('정수미'),
                ],
              ),
              ...List.generate(end - start + 1, (index) {
                return TableRow(
                  children: [
                    _buildTableCell((start + index).toString()),
                    _buildTableCell(''),
                    _buildTableCell(''),
                    _buildTableCell(''),
                    _buildTableCell(''),
                  ],
                );
              }),
            ],
          ),
          SizedBox(height: 20),
          Table(
            border: TableBorder.all(color: Colors.grey.shade800),
            columnWidths: {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(1.5),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                children: [
                  _buildTableCell('전반'),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('후반'),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('스코어'),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                ],
              ),
              TableRow(
                children: [
                  _buildTableCell('핸디 스코어'),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                  _buildTableCell(''),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 16),
      ),
    );
  }
}

class RankHandicapCard extends StatelessWidget {
  final String title;
  final String value;
  final String player;
  final Color color;

  RankHandicapCard({
    required this.title,
    required this.value,
    required this.player,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$value ',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              Text(
                player,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DotsIndicator extends StatelessWidget {
  final int dotsCount;
  final int position;

  DotsIndicator({required this.dotsCount, required this.position});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(dotsCount, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == position ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}