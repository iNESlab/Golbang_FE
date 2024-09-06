/* pages/models/user_profile.dart
* 이벤트 결과 조회 시 사용자 정보 (이름, 이미지, 스코어, 랭킹)
**/
import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';

class UserProfileWidget extends StatelessWidget {
  final UserProfile userProfile;

  const UserProfileWidget({Key? key, required this.userProfile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(userProfile.profileImage),
          radius: 30,
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userProfile.name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '총 점수: ${userProfile.sumScore}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '핸디캡 점수: ${userProfile.handicapScore}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '랭킹: ${userProfile.rank}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              '핸디캡 랭킹: ${userProfile.handicapRank}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }
}
