import 'package:flutter/material.dart';
import 'package:golbang/models/user_account.dart';
import 'package:golbang/models/get_statistics_overall.dart';

class BookmarkSection extends StatelessWidget {
  final UserAccount userAccount;
  final OverallStatistics overallStatistics;

  const BookmarkSection({super.key, required this.userAccount, required this.overallStatistics});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _buildInfoCards(),
      ),
    );
  }

  List<Widget> _buildInfoCards() {
    return [
      _buildSingleCard("평균 스코어", overallStatistics.averageScore?.toString() ?? 'N/A'),
      _buildSingleCard("베스트 스코어", overallStatistics.bestScore?.toString() ?? 'N/A'),
      _buildSingleCard("기록", overallStatistics.gamesPlayed?.toString() ?? 'N/A'),
    ];
  }

  Widget _buildSingleCard(String title, String description) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}