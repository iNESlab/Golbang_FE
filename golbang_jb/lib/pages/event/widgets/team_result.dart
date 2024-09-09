import 'package:flutter/material.dart';

class TeamResultWidget extends StatelessWidget {
  final int teamAGroupWins;
  final int teamBGroupWins;
  final String groupWinTeam;
  final int teamATotalScore;
  final int teamBTotalScore;
  final String totalWinTeam;

  const TeamResultWidget({
    Key? key,
    required this.teamAGroupWins,
    required this.teamBGroupWins,
    required this.groupWinTeam,
    required this.teamATotalScore,
    required this.teamBTotalScore,
    required this.totalWinTeam,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3), // 그림자 위치 조정
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Winner 타이틀
          Text(
            "Winner",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          _buildResultRow("Group", teamAGroupWins, teamBGroupWins, groupWinTeam),
          SizedBox(height: 10),
          _buildResultRow("Total Score", teamATotalScore, teamBTotalScore, totalWinTeam),
        ],
      ),
    );
  }

  Widget _buildResultRow(String title, int teamAValue, int teamBValue, String winTeam) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            _buildTeamScoreCard("A team", teamAValue, Colors.blue),
            SizedBox(width: 8),
            Text(
              ":",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            _buildTeamScoreCard("B team", teamBValue, Colors.red),
            SizedBox(width: 16),
            // 이긴 팀만 표시
            Text(
              winTeam,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamScoreCard(String teamName, int score, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            teamName,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: color),
          ),
          child: Text(
            score.toString(),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
