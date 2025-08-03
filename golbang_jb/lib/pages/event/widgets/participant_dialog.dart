import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/profile/member_profile.dart';
import '../../../repoisitory/secure_storage.dart';
import '../../../services/club_member_service.dart';
import '../../../widgets/common/circular_default_person_icon.dart';

class ParticipantDialog extends ConsumerStatefulWidget {
  final List<ClubMemberProfile> selectedParticipants;
  final int clubId;

  const ParticipantDialog({super.key, 
    required this.selectedParticipants,
    required this.clubId,
  });

  @override
  _ParticipantDialogState createState() => _ParticipantDialogState();
}

class _ParticipantDialogState extends ConsumerState<ParticipantDialog> {
  List<ClubMemberProfile> tempSelectedParticipants = [];
  List<ClubMemberProfile> allParticipants = [];
  List<ClubMemberProfile> filteredParticipants = []; // 필터링된 참가자 리스트
  bool isLoading = true;
  late ClubMemberService _clubMemberService;

  @override
  void initState() {
    super.initState();
    tempSelectedParticipants = List.from(widget.selectedParticipants);
    _clubMemberService = ClubMemberService(ref.read(secureStorageProvider));
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    try {
      List<ClubMemberProfile> participants = await _clubMemberService.getClubMemberProfileList(clubId: widget.clubId);
      setState(() {
        allParticipants = participants;
        filteredParticipants = participants; // 처음에는 전체 참가자 리스트로 초기화
        isLoading = false;
      });
    } catch (e) {
      log("Error fetching participants: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  bool _isAllSelected() {
    return filteredParticipants.every((p) => tempSelectedParticipants.contains(p));
  }

  void _toggleSelectAll() {
    setState(() {
      if (_isAllSelected()) {
        tempSelectedParticipants.removeWhere((p) => filteredParticipants.contains(p));
      } else {
        for (var p in filteredParticipants) {
          if (!tempSelectedParticipants.contains(p)) {
            tempSelectedParticipants.add(p);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '참여자 추가',
                style: TextStyle(color: Colors.green, fontSize: 25),
              ),
              TextButton(
                onPressed: _toggleSelectAll,
                child: Text(
                  _isAllSelected() ? '전체 해제' : '전체 선택',
                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )
        ),
      ),
      content: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: '이름 또는 닉네임으로 검색',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    // 검색 결과 필터링
                    filteredParticipants = allParticipants.where((participant) =>
                        participant.name.toLowerCase().contains(value.toLowerCase())).toList();
                  });
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredParticipants.length, // 필터링된 참가자 리스트로 표시
                  itemBuilder: (BuildContext context, int index) {
                    final participant = filteredParticipants[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.transparent,
                        child: participant.profileImage != null
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
                      title: Text(participant.name),
                      trailing: Checkbox(
                        value: tempSelectedParticipants.contains(participant),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value != null && value) {
                              tempSelectedParticipants.add(participant);
                            } else {
                              tempSelectedParticipants.remove(participant);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        Center(
          child: ElevatedButton(
            onPressed: () {
              context.pop(tempSelectedParticipants);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white, // 텍스트 색상을 흰색으로 설정
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('완료'),
          ),
        ),
      ],
    );
  }
}
