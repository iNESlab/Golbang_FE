/* TODO: 2025.3.22
* 지금 Member내부에 userProffile이 없어서, selectedMembers타입 불일치로 페이지로 새로 만들었음
* 향후, member 모델 내부에 user를 넣어서 페이지 통합시켜야함.
 */
import 'package:flutter/material.dart';

import '../../models/member.dart';

class AdminInvite extends StatelessWidget {
  final List<Member> selectedMembers;

  const AdminInvite({super.key, required this.selectedMembers});

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