import 'package:flutter/material.dart';
import '../../../models/create_participant.dart';

class GroupCard extends StatelessWidget {
  final String groupName;
  final List<CreateParticipant> members;
  final VoidCallback onAddParticipant;

  const GroupCard({super.key,
    required this.groupName,
    required this.members,
    required this.onAddParticipant,
    required TextStyle buttonTextStyle,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PARTY':
        return const Color(0xFF4D08BD);
      case 'ACCEPT':
        return const Color(0xFF08BDBD);
      case 'DENY':
        return const Color(0xFFF21B3F);
      case 'PENDING':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 그룹 이름과 추가 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                onPressed: onAddParticipant,
                icon: const Icon(Icons.add),
                label: Text(
                  groupName,
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  iconColor: Colors.white,
                  backgroundColor: Colors.teal,
                  minimumSize: const Size(80, 35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 참가자 리스트
          for (var member in members)
            Container(
              width: 100,
              height: 40,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getStatusColor(member.statusType!)),
              ),
              child: Center(child: Text(
                member.name,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(member.statusType!)),
              )),
            ),
        ],
      ),
    );
  }
}
