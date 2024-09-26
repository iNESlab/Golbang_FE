import 'package:flutter/material.dart';

import '../../models/profile/get_all_user_profile.dart';

class MemberInvite extends StatelessWidget {
  final List<GetAllUserProfile> selectedMembers;

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
