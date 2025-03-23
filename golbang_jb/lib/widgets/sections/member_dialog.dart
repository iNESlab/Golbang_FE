import 'package:flutter/material.dart';
import '../../models/member.dart';

class MemberDialog extends StatefulWidget {
  final List<Member> members;
  final List<Member> selectedMembers;
  final bool isAdminMode;

  const MemberDialog({super.key,
    required this.members,
    required this.isAdminMode,
    this.selectedMembers = const [],
  });

  @override
  _MemberDialogState createState() => _MemberDialogState();
}

class _MemberDialogState extends State<MemberDialog> {
  late List<Member> tempSelectedMembers;
  Map<int, bool> checkBoxStates = {}; // id를 키로 사용
  String searchQuery = ''; // 검색어를 저장할 변수

  @override
  void initState() {
    super.initState();
    tempSelectedMembers = widget.selectedMembers;
    // 각 멤버의 체크 상태를 초기화
    for (var member in tempSelectedMembers) {
      checkBoxStates[member.memberId] = true;
    }
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(),
            Text(
              widget.isAdminMode ? '관리자 추가' : '멤버 추가',
              style: const TextStyle(color: Colors.green, fontSize: 25),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop(tempSelectedMembers);
              },
            ),
          ],
        ),
      ),
      content: Container(
        color: Colors.white,
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: TextField(
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
                    searchQuery = value;
                  });
                },
              ),
            ),
            Expanded(
              child: widget.members.isEmpty
                  ? Center(
                child: Text(widget.isAdminMode
                    ? '추가된 멤버가 없습니다. 먼저 멤버를 추가하세요.'
                    : '검색 결과가 없습니다.'),
              )
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: widget.members.length,
                itemBuilder: (BuildContext context, int index) {
                  final member = widget.members[index];
                  final profileImage = member.profileImage;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      backgroundImage: profileImage.startsWith('http')
                          ? NetworkImage(profileImage)
                          : null,
                      child: !profileImage.startsWith('http')
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    title: Text(member.name),
                    trailing: Checkbox(
                      value: checkBoxStates[member.memberId] ?? false,
                      onChanged: (bool? value) {
                        setState(() {
                          checkBoxStates[member.memberId] = value ?? false;
                          if (value == true) {
                            if (!tempSelectedMembers.any(
                                    (m) => m.memberId == member.memberId)) {
                              tempSelectedMembers.add(member);
                            }
                          } else {
                            tempSelectedMembers.removeWhere(
                                    (m) => m.memberId == member.memberId);
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
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(tempSelectedMembers);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('완료'),
          ),
        ),
      ],
    );
  }

}
