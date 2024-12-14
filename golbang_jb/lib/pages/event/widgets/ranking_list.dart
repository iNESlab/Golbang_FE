import 'package:flutter/material.dart';
import '../../../models/participant.dart';

class RankingList extends StatelessWidget {
  final List<Participant> participants;

  const RankingList({required this.participants});

  @override
  Widget build(BuildContext context) {
    // 참가자 중 하나라도 유효한 sumScore가 있는지 확인 (N/A이면 데이터 없음 처리)
    bool hasValidScores = participants.any((participant) {
      return participant.sumScore != null && participant.sumScore != 'N/A';
    });

    if (!hasValidScores) {
      return _buildNoRankingData(); // 유효한 점수가 없으면 데이터 없음 메시지 출력
    }

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
        children: [
          // "Ranking" 텍스트를 추가
          Text(
            "Ranking",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10), // "Ranking" 텍스트와 리스트 간의 간격 추가

          // 참가자 리스트
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: participants.map((participant) {
              final String rank = participant.rank;
              final String name = participant.member?.name ?? 'Unknown';
              final String sumScore = participant.sumScore?.toString() ?? 'N/A';
              final String profileImage = participant.member?.profileImage ?? '';
              final int holeNumber = participant.holeNumber ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildRankIcon(rank),
                      SizedBox(width: 10),
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        child: ClipOval(
                          child: profileImage.isNotEmpty
                              ? Image.network(
                            profileImage,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/user_default.png',
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                              : Image.asset(
                            'assets/images/user_default.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        ],
      ),
    );
  }

  // Rank에 따른 아이콘 색상 및 텍스트 설정
  Widget _buildRankIcon(String rank) {
    Color color;
    String text;

    // rank에 따른 메달 색상 결정
    if (rank == '1' || rank == 'T1') {
      color = Colors.amber; // 금
      text = rank;
    } else if (rank == '2' || rank == 'T2') {
      color = Colors.grey; // 은
      text = rank;
    } else if (rank == '3' || rank == 'T3') {
      color = Colors.brown; // 동
      text = rank;
    } else {
      color = Colors.black54; // 기본 색상
      text = rank;
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
  // Ranking 데이터가 없을 때 보여줄 메시지 위젯
  Widget _buildNoRankingData() {
    return Center(
      child: Text(
        "Ranking data is not available.",
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}