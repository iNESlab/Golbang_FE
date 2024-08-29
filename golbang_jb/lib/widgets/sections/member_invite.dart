import 'package:flutter/material.dart';
import 'package:golbang/global_config.dart';

import '../../models/user_profile.dart';

class MemberInvite extends StatelessWidget {
  final List<UserProfile> selectedMembers;

  MemberInvite({required this.selectedMembers});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      children: selectedMembers.map((member) {
        // final memberData = users.firstWhere((m) => m.fullname == member);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              // backgroundImage: AssetImage(memberData.profileImage!),
              backgroundImage: member.profileImage.startsWith('http')
                  ? NetworkImage(member.profileImage)
                  : AssetImage(member.profileImage) as ImageProvider,
            ),
            SizedBox(height: 5),
            Text(
              member.name,
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }).toList(),
    );
  }
}
