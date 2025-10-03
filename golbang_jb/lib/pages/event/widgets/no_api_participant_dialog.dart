import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golbang/models/enum/event.dart';
import '../../../models/create_participant.dart';
import '../../../widgets/common/circular_default_person_icon.dart'; // CreateParticipant 모델 임포트

class ParticipantSelectionDialog extends StatefulWidget {
  final bool isTeam;
  final String groupName;
  final int max;
  final List<CreateParticipant> participants; // 전체 참여자 리스트
  final List<CreateParticipant> selectedParticipants; // 선택된 참여자 리스트
  final List<CreateParticipant> notOtherGroupParticipants; // 다른 조에서 선택된 참가자 리스트
  final Function(List<CreateParticipant>) onSelectionComplete; // 완료 콜백

  const ParticipantSelectionDialog({super.key, 
    required this.isTeam,
    required this.groupName,
    required this.participants,
    required this.selectedParticipants,
    required this.notOtherGroupParticipants, // 다른 조의 참가자 리스트를 추가로 받음
    required this.max,
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
        participant.groupType=0;
        participant.teamType=TeamConfig.NONE;

      } else if (_currentSelectedParticipants.length + 1 <= widget.max) {
        // 조별 인원수를 다 채우지 않았고, 선택되지 않은 경우 리스트에 추가
        participant.groupType = int.parse(widget.groupName.substring(1, 2)); // groupType 설정
        log('groupType: ${participant.groupType}');

        if (widget.isTeam) {
          String team = widget.groupName.substring(3);
          log('team: $team');

          participant.teamType = (team == 'A') ? TeamConfig.TEAM_A
              : (team == 'B') ? TeamConfig.TEAM_B
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
      content: SizedBox(
        width: double.maxFinite,
        child: ListView(
          children: widget.participants
              .where((participant) => widget.notOtherGroupParticipants.contains(participant)) // 다른 조에 이미 포함된 참가자를 제외
              .map((participant) {
            return CheckboxListTile(
              // 프로필 이미지와 이름 표시
              secondary: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.transparent, // 배경 투명
                child: participant.profileImage.startsWith('http')
                    ? ClipOval(
                  child: Image.network(
                    participant.profileImage,
                    fit: BoxFit.cover,
                    width: 60,
                    height: 60,
                    errorBuilder: (context, error, stackTrace) {
                      return const CircularIcon(); // 에러 시 동그란 아이콘 표시
                    },
                  ),
                )
                    : const CircularIcon(), // null일 때 동그란 아이콘
              ),
              title: Text(participant.name), // 이름 표시
              subtitle: Text('참석 여부: ${participant.statusType}'), // ID 표시
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
          onPressed: () => context.pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () {
            widget.onSelectionComplete(_currentSelectedParticipants); // 선택 완료 시 콜백
           context.pop(); // 다이얼로그 닫기
          },
          child: const Text("완료"),
        ),
      ],
    );
  }
}