import 'package:flutter/material.dart';
import 'package:golbang/models/user_account.dart';
import 'package:golbang/models/get_statistics_overall.dart';
import 'package:golbang/utils/reponsive_utils.dart';

class BookmarkSection extends StatelessWidget {
  final UserAccount userAccount;
  final OverallStatistics overallStatistics;

  const BookmarkSection({super.key, required this.userAccount, required this.overallStatistics});

  @override
  Widget build(BuildContext context) {
    // 화면 크기 가져오기
    double screenWidth = MediaQuery.of(context).size.width;
    Orientation orientation = MediaQuery.of(context).orientation;

    // 폰트 크기, 카드 크기, 패딩 크기 계산
    double fontSizeTitle = ResponsiveUtils.getBookmarkFontSizeTitle(screenWidth, orientation);
    double fontSizeDescription = ResponsiveUtils.getBookmarkFontSizeDescription(screenWidth, orientation);
    double cardWidth = ResponsiveUtils.getBookmarkCardWidth(screenWidth, orientation);
    double padding = ResponsiveUtils.getBookmarkPadding(screenWidth, orientation);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _buildInfoCards(cardWidth, fontSizeTitle, fontSizeDescription, padding, orientation),
      ),
    );
  }

  List<Widget> _buildInfoCards(
      double cardWidth, double fontSizeTitle, double fontSizeDescription, double padding, Orientation orientation) {
    return [
      _buildSingleCard("평균 스코어", overallStatistics.averageScore.toString(), cardWidth, fontSizeTitle,
          fontSizeDescription, padding, orientation),
      _buildSingleCard("베스트 스코어", overallStatistics.bestScore.toString(), cardWidth, fontSizeTitle,
          fontSizeDescription, padding, orientation),
      _buildSingleCard("기록", overallStatistics.gamesPlayed.toString(), cardWidth, fontSizeTitle,
          fontSizeDescription, padding, orientation),
    ];
  }

  Widget _buildSingleCard(String title, String description, double cardWidth, double fontSizeTitle,
      double fontSizeDescription, double padding, Orientation orientation) {
    return Container(
      width: cardWidth,
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding), // 반응형 패딩
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
      child: orientation == Orientation.portrait
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            title, // 세로모드에서는 제목
            style: TextStyle(fontSize: fontSizeTitle, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description, // 세로모드에서는 설명
            style: TextStyle(fontSize: fontSizeDescription, fontWeight: FontWeight.bold),
          ),
        ],
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            "$title : ", // 가로모드에서는 제목과 설명을 한 줄로
            style: TextStyle(fontSize: fontSizeTitle, fontWeight: FontWeight.bold),
          ),
          Text(
            description,
            style: TextStyle(fontSize: fontSizeDescription, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
