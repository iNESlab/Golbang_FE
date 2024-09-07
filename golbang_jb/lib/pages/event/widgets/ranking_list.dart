/*
pages/event/widgets/ranking_list.dart
이벤트에 참여한 사람들의 랭킹 정보를 표시
*/
import 'package:flutter/material.dart';
import '../../../models/participant.dart';

class RankingList extends StatelessWidget {
  final List<Participant> participants;

  const RankingList({required this.participants});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: participants.map((participant) {
          final String rank = participant.rank;
          final String name = participant.member?.name ?? 'Unknown';
          final String sumScore = participant.sumScore?.toString() ?? 'N/A';
          final String profileImage = participant.member?.profileImage ?? 'assets/images/user_default.png';
          final int holeNumber = participant.holeNumber ?? 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              leading: _buildRankIcon(int.tryParse(rank) ?? 0),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: NetworkImage(profileImage),
                        radius: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        name,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$holeNumber홀',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              trailing: Text(
                sumScore,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRankIcon(int rank) {
    Color color;
    String text;

    switch (rank) {
      case 1:
        color = Colors.amber;
        text = '1';
        break;
      case 2:
        color = Colors.grey;
        text = '2';
        break;
      case 3:
        color = Colors.brown;
        text = '3';
        break;
      default:
        color = Colors.grey[400]!;
        text = '$rank';
    }

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
