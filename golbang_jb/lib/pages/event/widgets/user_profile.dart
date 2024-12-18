/* pages/models/get_event_result_participants_ranks.dart
* 이벤트 결과 조회 시 사용자 정보 (이름, 이미지, 스코어, 랭킹)
**/
import 'package:flutter/material.dart';
import '../../../models/profile/get_event_result_participants_ranks.dart';

class UserProfileWidget extends StatelessWidget {
  final GetEventResultParticipantsRanks userProfile;

  const UserProfileWidget({Key? key, required this.userProfile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // 배경 흰색
        borderRadius: BorderRadius.circular(10), // 모서리 둥글게
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // 그림자
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 프로필 이미지
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.transparent, // 배경 투명
            child: userProfile.profileImage.startsWith('http')
                ? ClipOval(
              child: Image.network(
                userProfile.profileImage,
                fit: BoxFit.cover,
                width: 60,
                height: 60,
                errorBuilder: (context, error, stackTrace) {
                  return _buildCircularIcon(); // 에러 시 동그란 아이콘 표시
                },
              ),
            )
                : _buildCircularIcon(), // http로 시작하지 않을 때 동그란 아이콘
          ),
          SizedBox(width: 10),
          // 이름
          Expanded(
            child: Text(
              userProfile.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // 스코어 (기본)
          _buildScoreBox(
            label: 'Score',
            score: userProfile.sumScore.toString(),
          ),
          SizedBox(width: 10),
          // 랭킹 (기본)
          _buildScoreBox(
            label: 'My Rank',
            score: userProfile.rank,
          ),
        ],
      ),
    );
  }
  Widget _buildCircularIcon() {
    return ClipOval(
      child: Container(
        color: Colors.grey[300], // 배경색 (선택사항)
        width: 60,
        height: 60,
        child: Icon(
          Icons.person,
          size: 50,
          color: Colors.grey,
        ),
      ),
    );
  }

  // 스코어와 랭킹을 표시하는 박스 위젯
  Widget _buildScoreBox({required String label, required String score}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.green[100], // 배경색을 연한 녹색으로
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[800], // 텍스트 색상은 짙은 녹색
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            score,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
