import 'package:flutter/material.dart';

import '../../models/profile/get_all_user_profile.dart';

class MemberInvite extends StatelessWidget {
  final List<GetAllUserProfile> selectedMembers;

  const MemberInvite({super.key, required this.selectedMembers});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      children: selectedMembers.map((member) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey[200], // 연한 회색 배경
              backgroundImage: member.profileImage.isNotEmpty && member.profileImage.startsWith('http')
                  ? NetworkImage(member.profileImage)
                  : null, // 이미지가 없을 경우 null 설정
              child: member.profileImage.isEmpty || !member.profileImage.startsWith('http')
                  ? const Icon(Icons.person, color: Colors.grey) // 기본 사람 아이콘
                  : null, // 유효한 이미지가 있을 경우 null로 설정
            ),
            const SizedBox(width: 5),
            Text(
              member.name,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }).toList(),
    );
  }
}