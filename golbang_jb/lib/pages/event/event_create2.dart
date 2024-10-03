import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/pages/event/widgets/group_card.dart';
import 'package:golbang/pages/event/widgets/no_api_participant_dialog.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/club.dart';
import '../../models/create_event.dart';
import '../../models/create_participant.dart';
import '../../models/enum/event.dart';
import '../../models/profile/member_profile.dart';
import '../../provider/event/event_state_notifier_provider.dart';

class EventsCreate2 extends ConsumerStatefulWidget {
  final String title;
  final Club? selectedClub;
  final LatLng? selectedLocation;
  final String selectedSite;
  final DateTime startDate;
  final DateTime endDate;
  final List<ClubMemberProfile> selectedParticipants;
  final GameMode selectedGameMode;

  EventsCreate2({
    required this.title,
    required this.selectedClub,
    required this.selectedLocation,
    required this.selectedSite,
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
        profileImage: participant.profileImage,
        teamType: teamConfig,
        groupType: 1, // 0으로 하면, 에러 뜸.
      );
    }).toList();
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
      if (isTeam) {
        for (var participant in group.values.last) {
          if (!allParticipants.add(participant.memberId)) {
            print('참가자 중복입니다.true');
            return true;
          }
        }
      }
    }
    print('참가자 중복이 아닙니다.false');
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

    showDialog(
      context: context,
      builder: (context) {
        return ParticipantSelectionDialog(
          isTeam: isTeam,
          groupName: groupName,
          participants: _selectedParticipants, // 모든 참가자 리스트
          selectedParticipants: groupParticipants, // 현재 그룹에 선택된 참가자
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
    final event = CreateEvent(
      eventTitle: widget.title,
      location: widget.selectedLocation?.toString() ?? "Unknown Location",
      site: widget.selectedSite,
      startDateTime: widget.startDate,
      endDateTime: widget.endDate,
      repeatType: "NONE",
      gameMode: gameMode.value,
      alertDateTime: "",
    );

    // 이벤트 생성 호출 후 성공 여부에 따른 UI 처리
    final success = await ref
        .read(eventStateNotifierProvider.notifier)
        .createEvent(event, _selectedParticipants, widget.selectedClub!.id.toString());

    if (success) {
      // 성공 시 "이벤트 생성에 성공했습니다" 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이벤트 생성에 성공했습니다.')),
      );

      // 페이지 닫기
      Navigator.of(context).pop(true); // 첫 번째 페이지 닫기
      Navigator.of(context).pop(true); // 두 번째 페이지 닫기
    } else {
      // 실패 시 SnackBar로 오류 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이벤트 생성에 실패했습니다. 나중에 다시 시도해주세요.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // final eventState = ref.watch(eventStateNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text('이벤트 생성'),
        actions: [
          TextButton(
            onPressed: (hasDuplicateParticipants)
                ? null
                : _onCompletePressed,
            child: Text(
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
              child: Text('조 생성'),
            ),
            if (groups.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('추가 버튼을 눌러 멤버를 추가해보세요\n미선택시, 1조로 등록됩니다.'),
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
                                    _showParticipantSelectionDialog(groupNameB); // Same dialog for B team
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