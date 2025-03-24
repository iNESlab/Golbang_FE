import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/profile/get_all_user_profile.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/user_service.dart';

class UserDialog extends ConsumerStatefulWidget {
  final List<GetAllUserProfile> selectedUsers; // 기존 멤버 (체크 해제 불가능)
  final List<GetAllUserProfile> newSelectedUsers; // 새로 선택된 멤버 (체크 가능)
  final bool isAdminMode;

  const UserDialog({
    super.key,
    required this.selectedUsers,
    required this.newSelectedUsers,
    required this.isAdminMode,
  });

  @override
  _UserDialogState createState() => _UserDialogState();
}

class _UserDialogState extends ConsumerState<UserDialog> {
  late List<GetAllUserProfile> tempSelectedUsers;
  Map<int, bool> checkBoxStates = {};
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    // 기존 멤버와 새 멤버를 합쳐 초기화
    tempSelectedUsers = List.from(widget.selectedUsers)
      ..addAll(widget.newSelectedUsers);
    // 체크 상태 초기화
    for (var user in tempSelectedUsers) {
      checkBoxStates[user.accountId] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(secureStorageProvider);
    final UserService userService = UserService(storage);

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
                Navigator.of(context).pop(tempSelectedUsers);
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
              child: FutureBuilder<List<GetAllUserProfile>>(
                future: userService.getUserProfileList(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No users found.'));
                  } else {
                    final users = snapshot.data!;
                    // 검색어가 비어 있으면 아무것도 표시하지 않음
                    final filteredUsers = searchQuery.isEmpty
                        ? <GetAllUserProfile>[] // 검색어가 없으면 빈 리스트
                        : users.where((user) {
                      return user.name
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase());
                    }).toList();

                    if (filteredUsers.isEmpty && searchQuery.isNotEmpty) {
                      return const Center(child: Text('검색 결과가 없습니다.'));
                    } else if (searchQuery.isEmpty) {
                      return const Center(child: Text('검색어를 입력하세요.'));
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredUsers.length,
                      itemBuilder: (BuildContext context, int index) {
                        final user = filteredUsers[index];
                        final profileImage = user.profileImage;
                        final isOldMember =
                        widget.selectedUsers.any((e) => e.accountId == user.accountId);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            backgroundImage: profileImage.isNotEmpty &&
                                profileImage.startsWith('http')
                                ? NetworkImage(profileImage)
                                : null,
                            child: profileImage.isEmpty ||
                                !profileImage.startsWith('http')
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          title: Text(user.name),
                          trailing: Checkbox(
                            value: checkBoxStates[user.accountId] ?? false,
                            onChanged: isOldMember
                                ? null // 기존 멤버는 체크 해제 불가능
                                : (bool? value) {
                              setState(() {
                                checkBoxStates[user.accountId] = value ?? false;
                                if (value == true) {
                                  if (!tempSelectedUsers.any(
                                          (e) => e.accountId == user.accountId)) {
                                    tempSelectedUsers.add(user);
                                  }
                                } else {
                                  tempSelectedUsers.removeWhere(
                                          (e) => e.accountId == user.accountId);
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
          ],
        ),
      ),
      actions: <Widget>[
        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(tempSelectedUsers);
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