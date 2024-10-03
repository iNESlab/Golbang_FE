import 'package:flutter/material.dart';

class ToggleButtonsWidget extends StatefulWidget {
  // final Function(int) onSelectedMatchingType;
  final Function(int) onSelectedTeamType;
  final bool isTeam; //

  ToggleButtonsWidget({
    // required this.onSelectedMatchingType,
    required this.onSelectedTeamType,
    required this.isTeam,
  });

  @override
  _ToggleButtonsWidgetState createState() => _ToggleButtonsWidgetState();
}

class _ToggleButtonsWidgetState extends State<ToggleButtonsWidget> {
  // List<bool> isSelectedMatching = [true, false]; // 기본값은 '자동'
  List<bool> isSelectedTeam = [true, false]; // 기본값은 '개인'

  @override
  void initState() {
    super.initState();
    bool _isTeam = widget.isTeam == true;
    if (_isTeam) isSelectedTeam = [false, true];
  }
  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      color: Colors.black,
      selectedColor: Colors.white,
      fillColor: Colors.teal[200],
      borderWidth: 2,
      borderColor: Colors.teal,
      selectedBorderColor: Colors.teal,
      borderRadius: BorderRadius.circular(8),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Text('개인'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Text('팀'),
        ),
      ],
      onPressed: (int index) {
        setState(() {
          isSelectedTeam = [false, false];
          isSelectedTeam[index] = true;
        });
        widget.onSelectedTeamType(index); // 선택된 팀 구성 전달
      },
      isSelected: isSelectedTeam,
    );
      /* TODO: 아래 코드 복구시, 위에 return ~ 바로 위까지 제거하면 됨.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ToggleButtons(
          color: Colors.black, // 기본 텍스트 색상
          selectedColor: Colors.white, // 선택된 상태의 텍스트 색상
          fillColor: Colors.teal[200], // 선택된 버튼 배경색
          borderWidth: 2, // 테두리 두께
          borderColor: Colors.teal, // 테두리 색상
          selectedBorderColor: Colors.teal, // 선택된 상태의 테두리 색상
          borderRadius: BorderRadius.circular(8), // 버튼의 둥근 정도
          children: <Widget>[

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('자동'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('수동'),
            ),
          ],
          onPressed: (int index) {
            setState(() {
              isSelectedMatching = [false, false];
              isSelectedMatching[index] = true;
            });
            widget.onSelectedMatchingType(index); // 선택된 매칭 타입 전달
          },
          isSelected: isSelectedMatching,
        ),
        ToggleButtons(
          color: Colors.black,
          selectedColor: Colors.white,
          fillColor: Colors.teal[200],
          borderWidth: 2,
          borderColor: Colors.teal,
          selectedBorderColor: Colors.teal,
          borderRadius: BorderRadius.circular(8),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('개인'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('팀'),
            ),
          ],
          onPressed: (int index) {
            setState(() {
              isSelectedTeam = [false, false];
              isSelectedTeam[index] = true;
            });
            widget.onSelectedTeamType(index); // 선택된 팀 구성 전달
          },
          isSelected: isSelectedTeam,
        ),
     // ],
    );
         */
  }
}
