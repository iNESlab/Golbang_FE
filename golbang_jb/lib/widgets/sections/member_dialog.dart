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

  @override
  void initState() {
    super.initState();
    tempSelectedMembers = List.from(widget.isAdminMode ? widget.selectedAdmins : widget.selectedMembers);
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
                Navigator.of(context).pop(tempSelectedMembers);
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
              // 관리자를 추가할 때는 이미 추가된 멤버들 중에서만 선택 가능
              final selectableUsers = widget.isAdminMode
                  ? widget.selectedMembers.where((member) => users.contains(member)).toList()
                  : users;

              // 추가할 멤버가 없을 경우 메시지 표시
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
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: selectableUsers[index].profileImage.startsWith('http')
                          ? NetworkImage(selectableUsers[index].profileImage)
                          : AssetImage(selectableUsers[index].profileImage) as ImageProvider,
                    ),
                    title: Text(selectableUsers[index].name),
                    trailing: Checkbox(
                      value: tempSelectedMembers.contains(selectableUsers[index]),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value != null && value) {
                            tempSelectedMembers.add(selectableUsers[index]);
                          } else {
                            tempSelectedMembers.remove(selectableUsers[index]);
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
              Navigator.of(context).pop(tempSelectedMembers);
            },
            child: Text('완료'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ),
      ],
    );
  }
}
