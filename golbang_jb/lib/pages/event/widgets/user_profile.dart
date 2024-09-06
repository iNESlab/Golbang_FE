/*
pages/event/widgets/user_profile.dart
사용자 프로필 이미지를 표시하고 이름, 스트로크, 랭크 정보를 보여준다.
*/
import 'package:flutter/material.dart';

class UserProfile extends StatelessWidget {
  final String profileImage;
  final String name;
  final int stroke;
  final String rank;

  const UserProfile({
    required this.profileImage,
    required this.name,
    required this.stroke,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundImage: profileImage.isNotEmpty
              ? NetworkImage(profileImage)
              : AssetImage('assets/images/user_default.png') as ImageProvider,
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Stroke: $stroke'),
            Text('Rank: $rank'),
          ],
        ),
      ],
    );
  }
}
