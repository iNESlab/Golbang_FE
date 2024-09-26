import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/profile/get_all_user_profile.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/user_service.dart';

class MemberDialog extends ConsumerStatefulWidget {
  final List<GetAllUserProfile> selectedMembers;
  final List<GetAllUserProfile> selectedAdmins;
  final ValueChanged<List<GetAllUserProfile>> onMembersSelected;
  final bool isAdminMode;

  MemberDialog({
    required this.selectedMembers,
    required this.onMembersSelected,
    required this.isAdminMode,
    this.selectedAdmins = const [],
  });

  @override
  _MemberDialogState createState() => _MemberDialogState();
}

class _MemberDialogState extends ConsumerState<MemberDialog> {
  late List<GetAllUserProfile> tempSelectedMembers;
  Map<int, bool> checkBoxStates = {}; // id를 키로 사용

  @override
  void initState() {
    super.initState();
    tempSelectedMembers = List.from(widget.isAdminMode ? widget.selectedAdmins : widget.selectedMembers);
    // 각 멤버의 체크 상태를 초기화
    for (var member in tempSelectedMembers) {
      checkBoxStates[member.id] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(secureStorageProvider);
    final UserService userService = UserService(storage);

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(),
            Text(
              widget.isAdminMode ? '관리자 추가' : '멤버 추가',
              style: TextStyle(color: Colors.green, fontSize: 25),
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop(tempSelectedMembers); // 선택된 멤버 반환
              },
            ),
          ],
        ),
      ),
      content: Container(
        color: Colors.white,
        width: MediaQuery.of(context).size.width * 0.9,
        child: FutureBuilder<List<GetAllUserProfile>>(
          future: userService.getUserProfileList(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No users found.'));
            } else {
              final users = snapshot.data!;
              final selectableUsers = widget.isAdminMode
                  ? widget.selectedMembers.where((member) => users.contains(member)).toList()
                  : users;

              if (selectableUsers.isEmpty) {
                return Center(
                  child: Text(widget.isAdminMode
                      ? '추가된 멤버가 없습니다. 먼저 멤버를 추가하세요.'
                      : '사용 가능한 멤버가 없습니다.'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: selectableUsers.length,
                itemBuilder: (BuildContext context, int index) {
                  final user = selectableUsers[index];
                  final profileImage = user.profileImage;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      backgroundImage: profileImage.isNotEmpty && profileImage.startsWith('http')
                          ? NetworkImage(profileImage)
                          : null,
                      child: profileImage.isEmpty || !profileImage.startsWith('http')
                          ? Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    title: Text(user.name),
                    trailing: Checkbox(
                      value: checkBoxStates[user.id] ?? false, // id로 상태 관리
                      onChanged: (bool? value) {
                        setState(() {
                          // 체크박스 상태를 업데이트하고 멤버 추가/제거
                          checkBoxStates[user.id] = value ?? false;
                          if (value == true) {
                            // 중복 추가 방지: 리스트에 없을 때만 추가
                            if (!tempSelectedMembers.any((member) => member.id == user.id)) {
                              tempSelectedMembers.add(user);
                            }
                          } else {
                            // 체크 해제 시 리스트에서 제거
                            tempSelectedMembers.removeWhere((member) => member.id == user.id);
                          }
                        });
                      },
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      actions: <Widget>[
        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(tempSelectedMembers); // 선택된 멤버 반환
            },
            child: Text('완료'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ),
      ],
    );
  }
}
