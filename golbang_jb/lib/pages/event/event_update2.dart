import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/models/profile/member_profile.dart';
import 'package:golbang/pages/event/widgets/group_card.dart';
import 'package:golbang/pages/event/widgets/no_api_participant_dialog.dart';
import 'package:golbang/pages/event/widgets/toggle_bottons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/club.dart';
import '../../models/create_event.dart';
import '../../models/create_participant.dart';
import '../../models/enum/event.dart';
import '../../models/participant.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/event_service.dart';

class EventsUpdate2 extends ConsumerStatefulWidget {
  final int eventId;
  final String title;
  final Club? selectedClub;
  final LatLng selectedLocation;
  final String selectedSite;
  final DateTime startDate;
  final DateTime endDate;
  final List<ClubMemberProfile> selectedParticipants;
  final List<Participant> existingParticipants;
  final GameMode selectedGameMode;

  EventsUpdate2({
    required this.eventId,
    required this.title,
    required this.selectedClub,
    required this.selectedLocation,
    required this.selectedSite,
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
  TeamConfig teamConfig = TeamConfig.NONE;
  String groupSetting = '직접 설정';
  String numberOfGroups = '8개';
  String numberOfPlayers = '4명';
  bool isAutoMatching = false;
  bool isTeam = false;
  List<Map<String, List<CreateParticipant>>> groups = [];
  List<CreateParticipant> _selectedParticipants = [];
  bool hasDuplicateParticipants = false;
  bool areGroupsEmpty = true;
  bool allParticipantsAssigned = false;
  late EventService _eventService;

  @override
  void initState() {
    super.initState();
    _eventService = EventService(ref.read(secureStorageProvider));
    _initializeParticipants();
    isTeam = widget.existingParticipants.isEmpty ? false
        : widget.existingParticipants.first.teamType != TeamConfig.NONE.value;// 기존에 설정된 게임 모드 초기화
    _initializeGroups();
    gameMode = widget.selectedGameMode; // 기존에 설정된 게임 모드 초기화
  }

  void _initializeParticipants() {
    _selectedParticipants = widget.selectedParticipants.map((participant) {
      bool isExisting = widget.existingParticipants.contains(participant);
      late Participant existingParticipant;

      if (isExisting) {
        existingParticipant = widget.existingParticipants
            .firstWhere(
              (existing) => existing.member!.memberId == participant.memberId,
            );
      }

      return CreateParticipant(
        memberId: participant.memberId,
        name: participant.name,
        profileImage: participant.profileImage,
        teamType: teamConfig,
        groupType: isExisting ? existingParticipant.groupType : 0,
      );
    }).toList();
  }

  void _initializeGroups() {
    setState(() {
      groups.clear();

      List<CreateParticipant> existParticipants = widget.existingParticipants.map((participant) {
        print("${participant.member!.name} teamType: ${participant.teamType} groupType: ${participant.groupType}");
        return CreateParticipant(
          memberId: participant.member!.memberId,
          name: participant.member!.name,
          profileImage: participant.member!.profileImage ?? 'assets/images/user_default.png',
          teamType: participant.teamType == "NONE" ? TeamConfig.NONE
              : participant.teamType == "A" ? TeamConfig.TEAM_A
              : TeamConfig.TEAM_B,
          groupType: participant.groupType,
        );
      }).toList();

      for (CreateParticipant createParticipant in existParticipants) {
        String groupName = '조${createParticipant.groupType}';
        if (isTeam) groupName += ' ${createParticipant.teamType.value}'; // A, B 팀을 추가함
        print("=================");
        print("name : ${createParticipant.name}");
        print("isTeam: $isTeam");
        print("groupName: $groupName");

        // 그룹의 인덱스를 찾음
        int groupIndex = groups.indexWhere((group) => group.keys.contains(groupName));
        print("groupIndex: $groupIndex");

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
      _selectedParticipants.forEach((participant) {
        participant.groupType = 0;
        participant.teamType = TeamConfig.NONE;
      });
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
          print('참가자 중복입니다.true');
          return true;
        }
      }
      if(isTeam)
        for (var participant in group.values.last) {
          if (!allParticipants.add(participant.memberId)) {
            print('참가자 중복입니다.true');
            return true;
          }
        }
    }
    print('참가자 중복이 아닙니다.false');
    return false;
  }

  bool _checkIfAllParticipantsAssigned() {
    final assignedParticipants = <int>{};
    for (var group in groups) {
      for (var participant in group.values.first) {
        assignedParticipants.add(participant.memberId);
      }
      if(isTeam)
        for (var participant in group.values.last) {
          assignedParticipants.add(participant.memberId);
        }
    }
    print('참가자 할당여부 ${assignedParticipants.length == _selectedParticipants.length}');
    return assignedParticipants.length == _selectedParticipants.length;
  }

  void _validateForm() {
    setState(() {
      hasDuplicateParticipants = _checkForDuplicateParticipants();
      allParticipantsAssigned = _checkIfAllParticipantsAssigned();
      print("---------------------------------------------------");
    });
  }

  void _showParticipantSelectionDialog(String groupName) {
    List<CreateParticipant> groupParticipants = groups
        .firstWhere((group) => group.keys.first == groupName || group.keys.last == groupName)[groupName]!;

    bool Function(CreateParticipant) isSameGroup = (CreateParticipant participant) =>
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
    final eventData = CreateEvent(
      eventId: widget.eventId,
      eventTitle: widget.title,
      location: widget.selectedLocation.toString() ?? "Unknown Location",
      site: widget.selectedSite,
      startDateTime: widget.startDate,
      endDateTime: widget.endDate,
      repeatType: "NONE",
      gameMode: gameMode.value,
      alertDateTime: "",
    );

    bool success = await _eventService.updateEvent(
      event: eventData,
      participants: _selectedParticipants,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이벤트가 성공적으로 수정되었습니다.')),
      );
      Navigator.of(context).pop(true);
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이벤트 수정에 실패했습니다. 관리자만 수정할 수 있습니다. ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text('이벤트 수정'),
        actions: [
          TextButton(
            onPressed: (hasDuplicateParticipants || !allParticipantsAssigned)
                ? null
                : _onCompletePressed,
            child: Text(
              '완료',
              style: TextStyle(
                color: (hasDuplicateParticipants || !allParticipantsAssigned)
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
                      decoration: InputDecoration(
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
                  SizedBox(width: 20),
                  Expanded(
                    child: DropdownButtonFormField<bool>(
                      decoration: InputDecoration(
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
             SizedBox(height: 20),
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
                    decoration: InputDecoration(
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
                SizedBox(width: 20),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createGroups,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text(
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
                    Text('참가자 조를 지정해 주세요.\n모두 지정해야 완료됩니다.'),
                    SizedBox(height: 10),
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
                                buttonTextStyle: TextStyle(color: Colors.white),
                              ),
                              if (isTeam)
                                GroupCard(
                                  groupName: groupNameB,
                                  members: membersB,
                                  onAddParticipant: () {
                                    _showParticipantSelectionDialog(groupNameB);
                                  },
                                  buttonTextStyle: TextStyle(color: Colors.white),
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