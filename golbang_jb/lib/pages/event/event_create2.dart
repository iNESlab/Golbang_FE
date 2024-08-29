import 'package:flutter/material.dart';

class EventsCreate2 extends StatefulWidget {
  @override
  _EventsCreate2State createState() => _EventsCreate2State();
}

class _EventsCreate2State extends State<EventsCreate2> {
  String gameMode = '스트로크';
  String teamConfig = '개인';
  String groupSetting = '직접 설정';
  String numberOfGroups = '8개';
  String numberOfPlayers = '4명';
  List<Map<String, List<String>>> groups = [];

  void _createGroups() {
    int numGroups = int.parse(numberOfGroups.replaceAll('개', ''));
    int numPlayers = int.parse(numberOfPlayers.replaceAll('명', ''));
    setState(() {
      groups = List.generate(numGroups, (index) => {'조${index + 1}': List.generate(numPlayers, (_) => '')});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // 뒤로 가기 동작
          },
        ),
        title: Text('이벤트 생성'),
        actions: [
          TextButton(
            onPressed: () {
              // 완료 버튼 동작
            },
            child: Text(
              '완료',
              style: TextStyle(color: Colors.teal),
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
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: '게임모드',
                border: OutlineInputBorder(),
              ),
              value: gameMode,
              onChanged: (newValue) {
                setState(() {
                  gameMode = newValue!;
                });
              },
              items: ['스트로크'].map((mode) {
                return DropdownMenuItem<String>(
                  value: mode,
                  child: Text(mode),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionChip('자동'),
                _buildOptionChip('수동'),
                _buildOptionChip('개인', selected: true),
                _buildOptionChip('팀'),
              ],
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
                    items: ['8개', '7개', '6개', '5개', '4개'].map((number) {
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
                        children: groups.map((group) {
                          String groupName = group.keys.first;
                          return _buildGroupCard(groupName, group[groupName]!);
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

  Widget _buildOptionChip(String label, {bool selected = false}) {
    return ChoiceChip(
      label: Text(label),
      selected: teamConfig == label,
      onSelected: (isSelected) {
        setState(() {
          teamConfig = label;
        });
      },
      selectedColor: Colors.teal,
      backgroundColor: Colors.grey[200],
    );
  }

  Widget _buildGroupCard(String groupName, List<String> members) {
    return Container(
      margin: EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Text(groupName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          for (var i = 0; i < members.length; i++)
            Container(
              width: 100,
              height: 40,
              margin: EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: Center(child: Text(members[i])),
            ),
          ElevatedButton.icon(
            onPressed: () {
              // 멤버 추가 동작
            },
            icon: Icon(Icons.add),
            label: Text('추가'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              minimumSize: Size(100, 40),
            ),
          ),
        ],
      ),
    );
  }
}