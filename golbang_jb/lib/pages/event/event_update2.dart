import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/pages/event/widgets/group_card.dart';
import 'package:golbang/pages/event/widgets/no_api_participant_dialog.dart';
import 'package:golbang/pages/event/widgets/toggle_bottons.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/club.dart';
import '../../models/create_participant.dart';
import '../../models/enum/event.dart';
import '../../models/member_profile.dart';
import '../../models/participant.dart';
import '../../models/update_event_participant.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/event_service.dart';

class EventsUpdate2 extends ConsumerStatefulWidget {
  final int eventId;
  final String title;
  final Club? selectedClub;
  final LatLng? selectedLocation;
  final DateTime startDate;
  final DateTime endDate;
  final List<UpdateEventParticipant> selectedParticipants;
  final GameMode selectedGameMode;

  EventsUpdate2({
    required this.eventId,
    required this.title,
    required this.selectedClub,
    required this.selectedLocation,
    required this.startDate,
    required this.endDate,
    required this.selectedParticipants,
    required this.selectedGameMode,
  });

  @override
  _EventsUpdate2State createState() => _EventsUpdate2State();
}

class _EventsUpdate2State extends ConsumerState<EventsUpdate2> {
  GameMode gameMode = GameMode.STROKE;
  TeamConfig teamConfig = TeamConfig.NONE;
  String groupSetting = 'NONE'; // 기본값을 TeamConfig의 기본값과 일치시킴
  String numberOfGroups = '8';  // 예시로 '8개' 대신 '8'로 초기화
  String numberOfPlayers = '4'; // '4명' 대신 '4'로 초기화
  bool isAutoMatching = false;
  bool isTeam = false;
  List<Map<String, List<CreateParticipant>>> groups = [];
  List<CreateParticipant> _selectedParticipants = [];
  bool hasDuplicateParticipants = false;
  bool allParticipantsAssigned = false;
  late EventService _eventService;

  @override
  void initState() {
    super.initState();
    _eventService = EventService(ref.read(secureStorageProvider));
    gameMode = widget.selectedGameMode; // 기존에 설정된 게임 모드 초기화
    _initializeParticipants();
  }

  // String을 TeamConfig로 변환하는 메서드
  TeamConfig _getTeamConfigFromString(String groupSetting) {
    switch (groupSetting) {
      case 'NONE':
        return TeamConfig.NONE;
      case 'A':
        return TeamConfig.TEAM_A;
      case 'B':
        return TeamConfig.TEAM_B;
      default:
        return TeamConfig.NONE; // 기본값
    }
  }

  String _getStringFromTeamConfig(TeamConfig config) {
    return config.value; // TeamConfig를 String으로 변환
  }

  int _parseStringToInt(String value) {
    return int.parse(value.replaceAll(RegExp(r'[^0-9]'), '')); // '개', '명' 같은 문자를 제거하고 숫자로 변환
  }

  void _initializeParticipants() {
    Map<int, List<CreateParticipant>> participantsByGroup = {};

    for (var participant in widget.selectedParticipants) {
      int groupType = participant.groupType;

      participantsByGroup.putIfAbsent(groupType, () => []);

      participantsByGroup[groupType]!.add(CreateParticipant(
        memberId: participant.memberId,
        name: participant.name,
        profileImage: participant.profileImage,
        teamType: participant.teamType,
        groupType: participant.groupType,
      ));
    }

    setState(() {
      groups = participantsByGroup.entries.map((entry) {
        return {
          '조${entry.key}': entry.value,
        };
      }).toList();
      _validateForm();
    });
  }

  void _createGroups() {
    int numGroups = _parseStringToInt(numberOfGroups); // String을 int로 변환
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
          return true;
        }
      }
    }
    return false;
  }

  bool _checkIfAllParticipantsAssigned() {
    final assignedParticipants = <int>{};
    for (var group in groups) {
      for (var participant in group.values.first) {
        assignedParticipants.add(participant.memberId);
      }
    }
    return assignedParticipants.length == _selectedParticipants.length;
  }

  void _validateForm() {
    setState(() {
      hasDuplicateParticipants = _checkForDuplicateParticipants();
      allParticipantsAssigned = _checkIfAllParticipantsAssigned();
    });
  }

  void _showParticipantSelectionDialog(String groupName) {
    List<CreateParticipant> groupParticipants =
    groups.firstWhere((group) => group.keys.first == groupName)[groupName]!;

    showDialog(
      context: context,
      builder: (context) {
        return ParticipantSelectionDialog(
          groupName: groupName,
          participants: _selectedParticipants,
          selectedParticipants: groupParticipants,
          onSelectionComplete: (List<CreateParticipant> updatedParticipants) {
            setState(() {
              groups.firstWhere((group) => group.keys.first == groupName)[groupName] =
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              // groupSetting을 String으로 사용하되, TeamConfig로 변환할 때만 사용
              DropdownButtonFormField<TeamConfig>(
                decoration: InputDecoration(
                  labelText: '팀 설정',
                  border: OutlineInputBorder(),
                ),
                value: _getTeamConfigFromString(groupSetting), // String을 TeamConfig로 변환
                onChanged: (newValue) {
                  setState(() {
                    teamConfig = newValue!;
                    groupSetting = _getStringFromTeamConfig(newValue); // TeamConfig를 String으로 변환
                  });
                },
                items: TeamConfig.values.map((config) {
                  return DropdownMenuItem<TeamConfig>(
                    value: config,
                    child: Text(config.value),
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
                      items: ['8', '7', '6', '5', '4', '3', '2', '1'].map((number) {
                        return DropdownMenuItem<String>(
                          value: number,
                          child: Text('$number개'), // Display with '개' but store as number
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
                      items: ['4', '3', '2'].map((number) {
                        return DropdownMenuItem<String>(
                          value: number,
                          child: Text('$number명'), // Display with '명' but store as number
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: groups.map((group) {
                            String groupName = group.keys.first;
                            List<CreateParticipant> members = group[groupName]!;

                            return GroupCard(
                              groupName: groupName,
                              members: members,
                              onAddParticipant: () {
                                _showParticipantSelectionDialog(groupName);
                              },
                              buttonTextStyle: TextStyle(color: Colors.white),
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
      ),
    );
  }
}
