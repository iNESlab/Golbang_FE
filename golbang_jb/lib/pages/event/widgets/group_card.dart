import 'package:flutter/material.dart';
import '../../../models/create_participant.dart';

class GroupCard extends StatelessWidget {
  final String groupName;
  final List<CreateParticipant> members;
  final VoidCallback onAddParticipant;

  GroupCard({
    required this.groupName,
    required this.members,
    required this.onAddParticipant, required TextStyle buttonTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Text(groupName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          for (var member in members)
            Container(
              width: 100,
              height: 40,
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: Center(child: Text(member.name)),
            ),
          ElevatedButton.icon(
            onPressed: onAddParticipant,
            icon: Icon(Icons.add),
            label: Text(
              '추가',
              style: TextStyle(color: Colors.white)
            ),
            style: ElevatedButton.styleFrom(
              iconColor: Colors.white,
              backgroundColor: Colors.teal,
              minimumSize: Size(100, 40),
            ),
          ),
        ],
      ),
    );
  }
}
