import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/member.dart';

class MemberDialog extends StatefulWidget {
  final List<Member> members;
  final List<Member> selectedMembers;
  final bool isAdminMode;

  const MemberDialog({
    super.key,
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
    tempSelectedMembers = List.from(widget.selectedMembers);
    for (var member in tempSelectedMembers) {
      checkBoxStates[member.memberId] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔍 실시간 필터링된 멤버 목록
    final filteredMembers = widget.members.where((member) {
      final query = searchQuery.toLowerCase();
      final nameMatch = member.name.toLowerCase().contains(query);
      final idMatch = member.userId.toLowerCase().contains(query);
      return query.isEmpty || nameMatch || idMatch;
    }).toList();

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
              Text(
                widget.isAdminMode ? '관리자 추가' : '멤버 추가',
                style: const TextStyle(color: Colors.green, fontSize: 25),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  context.pop(tempSelectedMembers);
                },
              ),
            ],
          )
        ),
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        color: Colors.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: '이름 또는 ID로 검색',
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
              child: filteredMembers.isEmpty
                  ? const Center(child: Text('검색 결과가 없습니다.'))
                  : ListView.builder(
                itemCount: filteredMembers.length,
                itemBuilder: (context, index) {
                  final member = filteredMembers[index];
                  final profileImage = member.profileImage;
                  final isChecked = checkBoxStates[member.memberId] ?? false;

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
                    subtitle: Text(member.userId),
                    trailing: Checkbox(
                      value: isChecked,
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
              context.pop(tempSelectedMembers);
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
