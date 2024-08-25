import 'package:flutter/material.dart';
import 'package:golbang/global_config.dart';

class MemberInvite extends StatelessWidget {
  final List<String> selectedMembers;

  MemberInvite({required this.selectedMembers});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      children: selectedMembers.map((member) {
        final memberData = users.firstWhere((m) => m.fullname == member);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundImage: AssetImage(memberData.profileImage!),
            ),
            SizedBox(height: 5),
            Text(
              member,
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }).toList(),
    );
  }
}
