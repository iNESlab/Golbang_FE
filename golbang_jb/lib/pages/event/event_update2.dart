import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:go_router/go_router.dart';

import 'package:golbang/models/profile/member_profile.dart';
import 'package:golbang/pages/event/widgets/group_card.dart';
import 'package:golbang/pages/event/widgets/no_api_participant_dialog.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/club.dart';
import '../../models/create_event.dart';
import '../../models/create_participant.dart';
import '../../models/enum/event.dart';
import '../../models/participant.dart';
import '../../models/responseDTO/GolfClubResponseDTO.dart';
import '../../models/responseDTO/CourseResopnseDTO.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/event_service.dart';

class EventsUpdate2 extends ConsumerStatefulWidget {
  final int eventId;
  final String title;
  final Club? selectedClub;
  final LatLng selectedLocation;
  final GolfClubResponseDTO selectedGolfClub;
  final CourseResponseDTO selectedCourse;
  final DateTime startDate;
  final DateTime endDate;
  final List<ClubMemberProfile> selectedParticipants;
  final List<Participant> existingParticipants;
  final GameMode selectedGameMode;

  const EventsUpdate2({super.key, 
    required this.eventId,
    required this.title,
    required this.selectedClub,
    required this.selectedLocation,
    required this.selectedGolfClub,
    required this.selectedCourse,
    required this.startDate,
    required this.endDate,
    required this.selectedParticipants,
    required this.existingParticipants,
    required this.selectedGameMode,
  });

  @override
  _EventsUpdate2State createState() => _EventsUpdate2State();
}

class _EventsUpdate2State extends ConsumerState<EventsUpdate2> {
  GameMode gameMode = GameMode.STROKE;
  String groupSetting = '직접 설정';
  String numberOfGroups = '8개';
  String numberOfPlayers = '4명';
  bool isAutoMatching = false;
  bool isTeam = false;
  List<Map<String, List<CreateParticipant>>> groups = [];
  List<CreateParticipant> _finalParticipants = [];
  bool hasDuplicateParticipants = false;
  bool areGroupsEmpty = true;
  late EventService _eventService;
  bool _isLoading = false; // 🔧 추가: 로딩 상태

  @override
  void initState() {
    super.initState();
    _eventService = EventService(ref.read(secureStorageProvider));
    _initializeParticipants();

    isTeam = widget.existingParticipants.isNotEmpty &&
        widget.existingParticipants.any((participant) =>
        participant.teamType != TeamConfig.NONE.value); // 기존에 설정된 게임 모드 초기화

    _initializeGroups();
    gameMode = widget.selectedGameMode; // 기존에 설정된 게임 모드 초기화
  }

  void _initializeParticipants() {
    _finalParticipants = widget.selectedParticipants.map((participant) {
      Participant? existingParticipant = widget.existingParticipants.firstWhereOrNull(
            (existing) => existing.member!.memberId == participant.memberId,
      );

      var p = CreateParticipant(
        memberId: participant.memberId,
        name: participant.name,
        profileImage: participant.profileImage ?? '',
        teamType: existingParticipant==null ? TeamConfig.NONE
            : existingParticipant.teamType == "NONE" ? TeamConfig.NONE
            : existingParticipant.teamType == "A" ? TeamConfig.TEAM_A
            : TeamConfig.TEAM_B,
        groupType: existingParticipant!=null ? existingParticipant.groupType : 0,
      );

      log(">>>>>>>>>>>>>>>>>>>>>>>>>");
      log("name : ${p.name}");
      log("isTeam: ${p.teamType}");
      log("groupName: ${p.groupType}");

      return p;
    }).toList();
  }

  void _initializeGroups() {
    setState(() {
      groups.clear();
      List<CreateParticipant> existParticipants = widget.existingParticipants.map((participant) {
        return CreateParticipant(
          memberId: participant.member!.memberId,
          name: participant.member!.name,
          profileImage: participant.member!.profileImage ?? '',
          teamType: participant.teamType == "NONE" ? TeamConfig.NONE
              : participant.teamType == "A" ? TeamConfig.TEAM_A
              : TeamConfig.TEAM_B,
          groupType: participant.groupType,
        );
      }).toList();

      for (CreateParticipant createParticipant in existParticipants) {
        String groupName = '조${createParticipant.groupType}';
        if (isTeam) groupName += ' ${createParticipant.teamType.value}'; // A, B 팀을 추가함
        log("=================");
        log("name : ${createParticipant.name}");
        log("isTeam: $isTeam");
        log("groupName: $groupName");

        // 그룹의 인덱스를 찾음
        int groupIndex = groups.indexWhere((group) => group.keys.contains(groupName));
        log("groupIndex: $groupIndex");

        if (groupIndex != -1) {
          // 해당 그룹이 존재할 경우, 참가자를 추가
          groups[groupIndex][groupName]!.add(createParticipant);
        } else {
          // 해당 그룹이 없으면 새로운 그룹을 생성하여 추가
          isTeam ? createParticipant.teamType.value == "A"
              ? groups.add({ // A팀에 속할 때
                  "조${createParticipant.groupType} A": [createParticipant],
                  "조${createParticipant.groupType} B": [],
                })
              : groups.add({ // B팀에 속할 때
                  "조${createParticipant.groupType} A": [],
                  "조${createParticipant.groupType} B": [createParticipant],
                })
              : groups.add({ // 개인전일 때
                  groupName : [createParticipant],
                });
        }
      }
    });
  }

  void _createGroups() {
    int numGroups = int.parse(numberOfGroups.replaceAll('개', ''));
    setState(() {
      // 각 참가자의 groupType과 teamType을 0과 NONE으로 리셋
      for (var participant in _finalParticipants) {
        participant.groupType = 0;
        participant.teamType = TeamConfig.NONE;
      }
      groups.clear();
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

  bool _checkForDuplicateParticipants() {
    final allParticipants = <int>{};
    for (var group in groups) {
      for (var participant in group.values.first) {
        if (!allParticipants.add(participant.memberId)) {
          log('참가자 중복입니다.true');
          return true;
        }
      }
      if(isTeam) {
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
      log("---------------------------------------------------");
    });
  }

  void _showParticipantSelectionDialog(String groupName) {
    List<CreateParticipant> groupParticipants = groups
        .firstWhere((group) => group.keys.first == groupName || group.keys.last == groupName)[groupName]!;

    isSameGroup(CreateParticipant participant) =>
    participant.groupType == int.parse(groupName.substring(1, 2));

    List<CreateParticipant> notOtherGroupParticipants = _finalParticipants
        .where((p) => !isTeam ? isSameGroup(p) || p.groupType==0
        : p.groupType==0 || (isSameGroup(p) && p.teamType.value == groupName.substring(3)))
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return ParticipantSelectionDialog(
          isTeam: isTeam,
          groupName: groupName,
          participants: _finalParticipants, // 모든 참가자 리스트
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

  // 그룹의 숫자만 추출하여 순서대로 정렬하는 함수
  List<Map<String, List<CreateParticipant>>> _getSortedGroups(List<Map<String, List<CreateParticipant>>> groups) {
    return List<Map<String, List<CreateParticipant>>>.from(groups)
      ..sort((a, b) {
        // 첫 번째 키에서 조 번호 추출
        int groupNumberA = int.parse(a.keys.first.replaceAll(RegExp(r'[^0-9]'), ''));
        int groupNumberB = int.parse(b.keys.first.replaceAll(RegExp(r'[^0-9]'), ''));
        return groupNumberA.compareTo(groupNumberB);
      });
  }

  Future<void> _onCompletePressed() async {
    setState(() => _isLoading = true); // 🔧 추가: 로딩 시작
    
    try {
      final eventData = CreateEvent(
        eventId: widget.eventId,
        eventTitle: widget.title,
        location: widget.selectedLocation.toString() ?? "Unknown Location",
        golfClubId: widget.selectedGolfClub.golfClubId,
        golfCourseId: widget.selectedCourse.golfCourseId,
        startDateTime: widget.startDate,
        endDateTime: widget.endDate,
        repeatType: "NONE",
        gameMode: gameMode.value,
        alertDateTime: "",
      );
      for (var participant in _finalParticipants) {
        if (participant.groupType==0) {
          participant.groupType = 1;
          participant.teamType = isTeam
              ? TeamConfig.TEAM_A
              : TeamConfig.NONE;
        }
      }

      bool success = await _eventService.updateEvent(
        event: eventData,
        participants: _finalParticipants,
      );

      if(!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이벤트가 성공적으로 수정되었습니다.')),
        );
        context.go('/app/events/${widget.eventId}?refresh=${DateTime.now().millisecondsSinceEpoch}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이벤트 수정에 실패했습니다. 관리자만 수정할 수 있습니다. ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
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
    // 그룹을 조 번호 순서대로 정렬
    final sortedGroups = _getSortedGroups(groups);
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop()
        ),
        title: const Text('이벤트 수정'),
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
                      Text('수정 중...'),
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
          children: [ // TODO: 매칭 토글 복원시 여기부터
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
                          log('isTeam: $isTeam');
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
            if (sortedGroups.isNotEmpty)
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
                        children: sortedGroups.map((group) {
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
                                    _showParticipantSelectionDialog(groupNameB);
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