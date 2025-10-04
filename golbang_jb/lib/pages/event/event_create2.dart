import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/pages/event/widgets/group_card.dart';
import 'package:golbang/pages/event/widgets/no_api_participant_dialog.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';


import '../../models/club.dart';
import '../../models/create_event.dart';
import '../../models/create_participant.dart';
import '../../models/enum/event.dart';
import '../../models/profile/member_profile.dart';
import '../../models/responseDTO/GolfClubResponseDTO.dart';
import '../../models/responseDTO/CourseResopnseDTO.dart';
import '../../provider/event/event_state_notifier_provider.dart';

class EventsCreate2 extends ConsumerStatefulWidget {
  final String title;
  final Club? selectedClub;
  final LatLng? selectedLocation;
  final GolfClubResponseDTO selectedGolfClub;
  final CourseResponseDTO selectedCourse;
  final DateTime startDate;
  final DateTime endDate;
  final List<ClubMemberProfile> selectedParticipants;
  final GameMode selectedGameMode;

  const EventsCreate2({super.key, 
    required this.title,
    required this.selectedClub,
    required this.selectedLocation,
    required this.selectedGolfClub,
    required this.selectedCourse,
    required this.startDate,
    required this.endDate,
    required this.selectedParticipants,
    required this.selectedGameMode,
  });

  @override
  _EventsCreate2State createState() => _EventsCreate2State();
}

class _EventsCreate2State extends ConsumerState<EventsCreate2> {
  GameMode gameMode = GameMode.STROKE;
  TeamConfig teamConfig = TeamConfig.NONE;
  String groupSetting = '직접 설정';
  String numberOfGroups = '4개';
  String numberOfPlayers = '4명';
 // bool isAutoMatching = false;
  bool isTeam = false;
  List<Map<String, List<CreateParticipant>>> groups = [];
  List<CreateParticipant> _selectedParticipants = [];
  bool hasDuplicateParticipants = false;
  bool areGroupsEmpty = true;
  bool _isLoading = false; // 🔧 추가: 로딩 상태

  @override
  void initState() {
    super.initState();
    _initializeParticipants();
  }

  void _initializeParticipants() {
    _selectedParticipants = widget.selectedParticipants.map((participant) {
      return CreateParticipant(
        memberId: participant.memberId,
        name: participant.name,
        statusType: 'PENDING',
        profileImage: participant.profileImage ?? '',
        teamType: teamConfig,
        groupType: 0, // 0으로 하면, 에러 뜸.
      );
    }).toList();
  }

  bool _checkForDuplicateParticipants() {
    final allParticipants = <int>{};
    for (var group in groups) {
      for (var participant in group.values.first) {
        if (!allParticipants.add(participant.memberId)) {
          log('참가자 중복입니다.true');
          return true;
        }
      }
      if (isTeam) {
        for (var participant in group.values.last) {
          if (!allParticipants.add(participant.memberId)) {
            log('참가자 중복입니다.true');
            return true;
          }
        }
      }
    }
    log('참가자 중복이 아닙니다.false');
    return false;
  }

  void _validateForm() {
    setState(() {
      hasDuplicateParticipants = _checkForDuplicateParticipants();
    });
  }

  void _createGroups() {
    int numGroups = int.parse(numberOfGroups.replaceAll('개', ''));
    setState(() {
      // 각 참가자의 groupType과 teamType을 0과 NONE으로 리셋
      for (var participant in _selectedParticipants) {
        participant.groupType = 0;
        participant.teamType = TeamConfig.NONE;
      }
      groups.clear(); // Clear groups when toggling between team and individual
      groups = isTeam
          ? List.generate(
        numGroups,
            (index) => {
          '조${index + 1} A': [],
          '조${index + 1} B': [],
        },
      )
          : List.generate(
        numGroups,
            (index) => {
          '조${index + 1}': [],
        },
      );
      _validateForm();
    });
  }

  void _showParticipantSelectionDialog(String groupName) {
    List<CreateParticipant> groupParticipants = groups
        .firstWhere((group) => group.keys.first == groupName || group.keys.last == groupName)[groupName]!;

    isSameGroup(CreateParticipant participant) =>
      participant.groupType == int.parse(groupName.substring(1, 2));

    List<CreateParticipant> notOtherGroupParticipants = _selectedParticipants
        .where((p) => !isTeam ? isSameGroup(p) || p.groupType==0
        : p.groupType==0 || (isSameGroup(p) && p.teamType.value == groupName.substring(3)))
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return ParticipantSelectionDialog(
          isTeam: isTeam,
          groupName: groupName,
          participants: _selectedParticipants, // 모든 참가자 리스트
          selectedParticipants: groupParticipants, // 현재 그룹에 선택된 참가자
          notOtherGroupParticipants: notOtherGroupParticipants,
          max: int.parse(numberOfPlayers.substring(0,1)),
          onSelectionComplete: (List<CreateParticipant> updatedParticipants) {
            setState(() {
              groups.firstWhere((group) => group.keys.contains(groupName))[groupName] = updatedParticipants;
              _validateForm();
            });
          },
        );
      },
    );
  }

  Future<void> _onCompletePressed() async {
    setState(() => _isLoading = true); // 🔧 추가: 로딩 시작
    
    try {
      final event = CreateEvent(
        eventTitle: widget.title,
        location: widget.selectedLocation?.toString() ?? "Unknown Location",
        golfClubId: widget.selectedGolfClub.golfClubId,
        golfCourseId: widget.selectedCourse.golfCourseId,
        startDateTime: widget.startDate,
        endDateTime: widget.endDate,
        repeatType: "NONE",
        gameMode: gameMode.value,
        alertDateTime: "",
      );

      for (var participant in _selectedParticipants) {
        if (participant.groupType==0) {
          participant.groupType = 1;
          participant.teamType = isTeam
              ? TeamConfig.TEAM_A
              : TeamConfig.NONE;
        }
      }

      // 이벤트 생성 호출 후 성공 여부에 따른 UI 처리
      await ref
          .read(eventStateNotifierProvider.notifier)
          .createEvent(event, _selectedParticipants, widget.selectedClub!.id.toString());

      if(!mounted) return;

      // 성공 시 "이벤트 생성에 성공했습니다" 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이벤트 생성에 성공했습니다.')),
      );
        // 페이지 닫기
      context.go('/app/events?refresh=${DateTime.now().millisecondsSinceEpoch}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // 🔧 추가: 로딩 종료
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // final eventState = ref.watch(eventStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop()
        ),
        title: const Text('이벤트 생성'),
        actions: [
          TextButton(
            onPressed: (hasDuplicateParticipants || _isLoading)
                ? null
                : _onCompletePressed, // 🔧 추가: 로딩 중 버튼 비활성화
            child: _isLoading
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('생성 중...'),
                    ],
                  )
                : Text(
                    '완료',
                    style: TextStyle(
                      color: (hasDuplicateParticipants)
                          ? Colors.grey
                          : Colors.teal,
                    ),
                  ),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [ // TODO: 매칭 토ㄱ원시 여기부터
            Row(
              children: [ // TODO: 여기까지 삭제
                Expanded(
                  child: DropdownButtonFormField<GameMode>(
                        decoration: const InputDecoration(
                          labelText: '게임모드',
                          border: OutlineInputBorder(),
                    ),
                    value: gameMode,
                    onChanged: (newValue) {
                      setState(() {
                        gameMode = newValue!;
                        _validateForm();
                      });
                    },
                    items: GameMode.values.map((mode) {
                      return DropdownMenuItem<GameMode>(
                        value: mode,
                        child: Text(
                          mode == GameMode.STROKE ? '스트로크' : mode.toString(),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: DropdownButtonFormField<bool>(
                    decoration: const InputDecoration(
                      labelText: '팀/개인전',
                      border: OutlineInputBorder(),
                    ),
                    value: isTeam,
                    onChanged: (newValue) {
                      setState(() {
                        isTeam = newValue!;
                        _createGroups();
                        _validateForm();
                      });
                    },
                    items: ['개인전', '팀전'].asMap().entries.map((entry) {
                      int idx = entry.key;  // 인덱스 추출
                      String value = entry.value;  // 해당 문자열 ('개인전' 또는 '팀전')
                      return DropdownMenuItem<bool>(
                        value: idx == 1,  // 인덱스를 value로 지정
                        child: Text(value),  // 보여줄 텍스트는 문자열
                      );
                    }).toList(),
                  ),
                ),
              ],
          ),
            const SizedBox(height: 20),
            /*
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: '직접 설정',
                border: OutlineInputBorder(),
              ),
              value: groupSetting,
              onChanged: (newValue) {
                setState(() {
                  groupSetting = newValue!;
                });
              },
              items: ['직접 설정'].map((setting) {
                return DropdownMenuItem<String>(
                  value: setting,
                  child: Text(setting),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            */
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '조(최대 갯수)',
                      border: OutlineInputBorder(),
                    ),
                    value: numberOfGroups,
                    onChanged: (newValue) {
                      setState(() {
                        numberOfGroups = newValue!;
                      });
                    },
                    items: ['8개', '7개', '6개', '5개', '4개', '3개', '2개', '1개'].map((number) {
                      return DropdownMenuItem<String>(
                        value: number,
                        child: Text(number),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: '조별 인원 수(최대)',
                      border: OutlineInputBorder(),
                    ),
                    value: numberOfPlayers,
                    onChanged: (newValue) {
                      setState(() {
                        numberOfPlayers = newValue!;
                      });
                    },
                    items: ['4명', '3명', '2명'].map((number) {
                      return DropdownMenuItem<String>(
                        value: number,
                        child: Text(number),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createGroups,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                '조 생성',
                style: TextStyle(color: Colors.white),  // 글자 색을 흰색으로 설정
              ),
            ),
            if (groups.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('참가자 조를 지정해 주세요.\n미선택시 \'1조\' 혹은 \'A팀 1조\'으로 지정됩니다.'),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: groups.map((group) {
                          String groupNameA = group.keys.first;
                          String groupNameB = group.keys.last;

                          List<CreateParticipant> membersA = group[groupNameA]!;
                          List<CreateParticipant> membersB = group[groupNameB]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GroupCard(
                                groupName: groupNameA,
                                members: membersA,
                                onAddParticipant: () {
                                  _showParticipantSelectionDialog(groupNameA);
                                },
                                buttonTextStyle: const TextStyle(color: Colors.white),
                              ),
                              if (isTeam)
                                GroupCard(
                                  groupName: groupNameB,
                                  members: membersB,
                                  onAddParticipant: () {
                                    _showParticipantSelectionDialog(groupNameB); // Same dialog for B team
                                  },
                                  buttonTextStyle: const TextStyle(color: Colors.white),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}