import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  List<GetAllUserProfile> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    tempSelectedUsers = List.from(widget.selectedUsers)..addAll(widget.newSelectedUsers);
    for (var user in tempSelectedUsers) {
      checkBoxStates[user.accountId] = true;
    }
    loadUsers(); // 🔁 최초 한 번만 불러오기
  }

  Future<void> loadUsers() async {
    final storage = ref.read(secureStorageProvider);
    final userService = UserService(storage);

    try {
      final fetchedUsers = await userService.getUserProfileList();
      setState(() {
        users = fetchedUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = searchQuery.isEmpty
        ? <GetAllUserProfile>[]
        : users.where((user) {
      final query = searchQuery.toLowerCase();
      final idMatch = user.userId?.toLowerCase().contains(query) ?? false;
      final nameMatch = user.name.toLowerCase().contains(query);
      return idMatch || nameMatch;
    }).toList();

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      titlePadding: EdgeInsets.zero,
      title: _buildTitle(context),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        color: Colors.white,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildUserList(filteredUsers),
            ),
          ],
        ),
      ),
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: () {
              context.pop(tempSelectedUsers);
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

  Widget _buildTitle(BuildContext context) {
    return Container(
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
                context.pop(tempSelectedUsers);
              },
            ),
          ],
        )
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
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
    );
  }

  Widget _buildUserList(List<GetAllUserProfile> filteredUsers) {
    if (searchQuery.isEmpty) {
      return const Center(child: Text('검색어를 입력하세요.'));
    }

    if (filteredUsers.isEmpty) {
      return const Center(child: Text('검색 결과가 없습니다.'));
    }

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        final profileImage = user.profileImage;
        final isOldMember = widget.selectedUsers.any((e) => e.accountId == user.accountId);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[200],
            backgroundImage: profileImage.isNotEmpty && profileImage.startsWith('http')
                ? NetworkImage(profileImage)
                : null,
            child: profileImage.isEmpty || !profileImage.startsWith('http')
                ? const Icon(Icons.person, color: Colors.grey)
                : null,
          ),
          title: Text(user.name),
          subtitle: Text(user.userId ?? 'UnknownId'),
          trailing: Checkbox(
            value: checkBoxStates[user.accountId] ?? false,
            onChanged: isOldMember
                ? null
                : (bool? value) {
              setState(() {
                checkBoxStates[user.accountId] = value ?? false;
                if (value == true) {
                  if (!tempSelectedUsers.any((e) => e.accountId == user.accountId)) {
                    tempSelectedUsers.add(user);
                  }
                } else {
                  tempSelectedUsers.removeWhere((e) => e.accountId == user.accountId);
                }
              });
            },
          ),
        );
      },
    );
  }
}
