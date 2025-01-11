import 'package:flutter/material.dart';
import 'package:golbang/models/user_account.dart';
import 'package:golbang/models/get_statistics_overall.dart';

class BookmarkSection extends StatelessWidget {
  final UserAccount userAccount;
  final OverallStatistics overallStatistics;

  const BookmarkSection({super.key, required this.userAccount, required this.overallStatistics});

  @override
  Widget build(BuildContext context) {
    // 화면 크기 가져오기
    double screenWidth = MediaQuery.of(context).size.width; // 화면 너비
    double screenHeight = MediaQuery.of(context).size.height; // 화면 높이

    // 폰트 크기, 카드 크기, 패딩 크기 계산
    double fontSizeTitle = screenWidth > 600 ? screenWidth * 0.025 : screenWidth * 0.03; // 화면 너비에 맞춰 폰트 크기 조정
    double fontSizeDescription = screenWidth > 600 ? screenWidth * 0.028 : screenWidth * 0.035; // 설명 폰트 크기 증가
    double cardWidth = screenWidth > 600 ? screenWidth * 0.25 : screenWidth * 0.3; // 화면 너비에 비례하여 카드 크기 조정
    double padding = screenWidth > 600 ? screenWidth * 0.01 : screenWidth * 0.015; // 화면 너비에 맞춰 패딩 조정

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _buildInfoCards(cardWidth, fontSizeTitle, fontSizeDescription, padding),
      ),
    );
  }

  List<Widget> _buildInfoCards(double cardWidth, double fontSizeTitle, double fontSizeDescription, double padding) {
    return [
      _buildSingleCard("평균 스코어", overallStatistics.averageScore.toString() ?? 'N/A', cardWidth, fontSizeTitle, fontSizeDescription, padding),
      _buildSingleCard("베스트 스코어", overallStatistics.bestScore.toString() ?? 'N/A', cardWidth, fontSizeTitle, fontSizeDescription, padding),
      _buildSingleCard("기록", overallStatistics.gamesPlayed.toString() ?? 'N/A', cardWidth, fontSizeTitle, fontSizeDescription, padding),
    ];
  }

  Widget _buildSingleCard(String title, String description, double cardWidth, double fontSizeTitle, double fontSizeDescription, double padding) {
    return Container(
      width: cardWidth,
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding), // 반응형 패딩 크기
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(fontSize: fontSizeTitle, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(fontSize: fontSizeDescription, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
