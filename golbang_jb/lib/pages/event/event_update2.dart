import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/models/profile/member_profile.dart';
import 'package:golbang/pages/event/widgets/group_card.dart';
import 'package:golbang/pages/event/widgets/no_api_participant_dialog.dart';
import 'package:golbang/pages/event/widgets/toggle_bottons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/club.dart';
import '../../models/create_participant.dart';
import '../../models/enum/event.dart';
import '../../models/participant.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/event_service.dart';

class EventsUpdate2 extends ConsumerStatefulWidget {
  final int eventId;
  final String title;
  final Club? selectedClub;
  final LatLng? selectedLocation;
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
    _initializeGroups();
    gameMode = widget.selectedGameMode; // 기존에 설정된 게임 모드 초기화
  }

  void _initializeParticipants() {
    // 기존 참가자 정보에서 groupType을 찾아 매핑
    _selectedParticipants = widget.selectedParticipants.map((participant) {
      // existingParticipants에서 해당 참가자의 그룹 정보를 찾음
      Participant? existingParticipant;
      try {
        // existingParticipants에서 해당 참가자의 그룹 정보를 찾음
        existingParticipant = widget.existingParticipants.firstWhere(
              (existing) => existing.member!.memberId == participant.memberId,
        );
      } catch (e) {
        // 참가자를 찾지 못하면 null로 설정
        existingParticipant = null;
      }

      // groupType을 가져오고, 없으면 null로 설정
      int groupType = existingParticipant?.groupType ?? 0;

      return CreateParticipant(
        memberId: participant.memberId,
        name: participant.name,
        profileImage: participant.profileImage,
        teamType: teamConfig,
        groupType: groupType, // 기존 참가자의 groupType 적용
      );
    }).toList();
  }


  void _initializeGroups() {
    setState(() {
      // 먼저 groups 리스트를 초기화합니다.
      groups.clear();

      List<CreateParticipant> existParticipants = widget.existingParticipants.map((participant) {
        return CreateParticipant(
          memberId: participant.member!.memberId,
          name: participant.member!.name,
          profileImage: participant.member!.profileImage??'assets/images/user_default.png',
          teamType: teamConfig,
          groupType: participant.groupType,
        );
      }).toList();

      // 모든 참가자에 대해 그룹을 설정
      for (CreateParticipant createParticipant in existParticipants) {
        String groupName = '조${createParticipant.groupType}';

        // 그룹이 이미 존재하는지 확인
        var existingGroup = groups.firstWhere(
                (group) => group.keys.contains(groupName),
            orElse: () => {}
        );

        // 그룹이 존재하면 해당 그룹에 참가자를 추가하고, 없으면 새로운 그룹을 생성하여 추가
        if (existingGroup.isNotEmpty) {
          existingGroup[groupName]!.add(createParticipant);
        } else {
          groups.add({
            groupName: [createParticipant]
          });
        }
      }
    });
  }

  void _createGroups() {
    int numGroups = int.parse(numberOfGroups.replaceAll('개', ''));
    setState(() {
      groups = List.generate(
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
    List<CreateParticipant> groupParticipants =
    groups.firstWhere((group) => group.keys.first == groupName)[groupName]!;

    showDialog(
      context: context,
      builder: (context) {
        return ParticipantSelectionDialog(
          isTeam: isTeam,
          groupName: groupName,
          participants: _selectedParticipants,
          selectedParticipants: groupParticipants,
          onSelectionComplete: (List<CreateParticipant> updatedParticipants) {
            setState(() {
              groups
                  .firstWhere((group) => group.keys.first == groupName)[groupName] =
                  updatedParticipants;
              _validateForm();
            });
          },
        );
      },
    );
  }

  Future<void> _onCompletePressed() async {
    final eventData = {
      "event_title": widget.title,
      "location": widget.selectedLocation?.toString() ?? "Unknown Location",
      "start_date_time": widget.startDate.toIso8601String(),
      "end_date_time": widget.endDate.toIso8601String(),
      "game_mode": widget.selectedGameMode.value,
      "participants": _selectedParticipants.map((p) => p.toJson()).toList(),
    };

    bool success = await _eventService.updateEvent(widget.eventId, eventData);

    if (success) {
      Navigator.of(context).pop(true);
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(content: Text('이벤트가 성공적으로 수정되었습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이벤트 수정에 실패했습니다.')),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<GameMode>(
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
            SizedBox(height: 20),
            ToggleButtonsWidget(
              onSelectedMatchingType: (int index) {
                setState(() {
                  isAutoMatching = index == 0;
                });
              },
              onSelectedTeamType: (int index) {
                setState(() {
                  isTeam = index == 1;
                });
              },
            ),
            SizedBox(height: 20),
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
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: '팀 수',
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
                      labelText: '인원 수',
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
              child: Text('조 생성'),
            ),
            if (groups.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('추가 버튼을 눌러 멤버를 추가해보세요'),
                    SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start, // 상단 정렬 설정
                        children: groups.map((group) {
                          String groupName = group.keys.first;
                          List<CreateParticipant> members = group[groupName]!;

                          return GroupCard(
                            groupName: groupName,
                            members: members,
                            onAddParticipant: () {
                              _showParticipantSelectionDialog(groupName);
                            }, buttonTextStyle: TextStyle(color: Colors.white),
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