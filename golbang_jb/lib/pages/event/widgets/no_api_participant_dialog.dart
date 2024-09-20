import 'package:flutter/material.dart';
import 'package:golbang/models/enum/event.dart';
import '../../../models/create_participant.dart'; // CreateParticipant 모델 임포트

class ParticipantSelectionDialog extends StatefulWidget {
  final bool isTeam;
  final String groupName;
  final List<CreateParticipant> participants; // 전체 참여자 리스트
  final List<CreateParticipant> selectedParticipants; // 선택된 참여자 리스트
  final Function(List<CreateParticipant>) onSelectionComplete; // 완료 콜백

  ParticipantSelectionDialog({
    required this.isTeam,
    required this.groupName,
    required this.participants,
    required this.selectedParticipants,
    required this.onSelectionComplete,
  });

  @override
  _ParticipantSelectionDialogState createState() =>
      _ParticipantSelectionDialogState();
}

class _ParticipantSelectionDialogState
    extends State<ParticipantSelectionDialog> {
  late List<CreateParticipant> _currentSelectedParticipants;

  @override
  void initState() {
    super.initState();
    // 선택된 참여자 리스트를 복사하여 다이얼로그 내에서 사용
    _currentSelectedParticipants = List.from(widget.selectedParticipants);
  }

  bool _isParticipantSelected(CreateParticipant participant) {
    // 선택된 참가자가 리스트에 있는지 확인 (memberId 기준으로)
    return _currentSelectedParticipants
        .any((selected) => selected.memberId == participant.memberId);
  }

  void _toggleParticipantSelection(CreateParticipant participant) {
    setState(() {
      if (_isParticipantSelected(participant)) {
        // 선택된 경우 리스트에서 제거
        _currentSelectedParticipants.removeWhere(
                (selected) => selected.memberId == participant.memberId);
      } else {
        // 선택되지 않은 경우 리스트에 추가 (기존 객체 사용)
        participant.groupType = int.parse(widget.groupName.substring(1,2)); // groupType 설정
        print('groupType: ${participant.groupType}');

        if(widget.isTeam){
          String team = widget.groupName.substring(3);
          print('team: ${team}');

          participant.teamType = ( team == 'A') ? TeamConfig.TEAM_A
              : ( team == 'B') ? TeamConfig.TEAM_B
              : TeamConfig.NONE;
        }

        _currentSelectedParticipants.add(participant);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("${widget.groupName} 참여자 선택"),
      content: Container(
        width: double.maxFinite,
        child: ListView(
          children: widget.participants.map((participant) {
            return CheckboxListTile(
              // 프로필 이미지와 이름 표시
              secondary: CircleAvatar(
                backgroundImage: participant.profileImage.startsWith('http')
                    ? NetworkImage(participant.profileImage)
                    : AssetImage(participant.profileImage) as ImageProvider,
                radius: 20,
              ),
              title: Text(participant.name), // 이름 표시
              subtitle: Text('ID: ${participant.memberId.toString()}'), // ID 표시
              value: _isParticipantSelected(participant), // 선택 상태 표시
              onChanged: (bool? selected) {
                _toggleParticipantSelection(participant); // 선택/해제 처리
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('취소'),
        ),
        TextButton(
          onPressed: () {
            widget.onSelectionComplete(_currentSelectedParticipants); // 선택 완료 시 콜백
            Navigator.of(context).pop(); // 다이얼로그 닫기
          },
          child: Text("완료"),
        ),
      ],
    );
  }
}
