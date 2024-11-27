import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/pages/group/widgets/admin_button_widget.dart';
import 'package:golbang/pages/group/widgets/member_button_widget.dart';
import 'package:golbang/services/user_service.dart';
import 'package:golbang/widgets/sections/member_dialog.dart';
import 'package:golbang/widgets/sections/member_invite.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/profile/get_all_user_profile.dart';
import '../../provider/club/club_state_provider.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/group_service.dart';
import '../profile/profile_screen.dart';

class GroupCreatePage extends ConsumerStatefulWidget {
  @override
  _GroupCreatePageState createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends ConsumerState<GroupCreatePage> {
  List<GetAllUserProfile> selectedAdmins = [];
  List<GetAllUserProfile> selectedMembers = [];
  TextEditingController _groupNameController = TextEditingController();
  TextEditingController _groupDescriptionController = TextEditingController();
  XFile? _imageFile;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile;
    });
  }

  @override
  void initState() {
    super.initState();
    // 로그인된 사용자 정보를 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userAccountProvider.notifier).loadUserAccount();  // 상태 업데이트만 진행
    });
  }


  // `GetAllUserProfile`을 사용하는 멤버 다이얼로그
  void _showMemberDialog(bool isAdminMode) {
    showDialog<List<GetAllUserProfile>>(
      context: context,
      builder: (BuildContext context) {
        return MemberDialog(
          selectedMembers: selectedMembers, // 여기에 항상 selectedMembers를 전달
          onMembersSelected: (List<GetAllUserProfile> members) {
            setState(() {
              if (isAdminMode) {
                selectedAdmins = members;
              } else {
                selectedMembers = members;
              }
            });
          },
          isAdminMode: isAdminMode,
          selectedAdmins: selectedAdmins,
        );
      },
    ).then((result) {
      if (result != null) {
        setState(() {
          if (isAdminMode) {
            selectedAdmins = result;
          } else {
            selectedMembers = result;
          }
        });
      }
    });
  }

  void _onComplete() async {
    String groupName = _groupNameController.text;
    String groupDescription = _groupDescriptionController.text;

    if (groupName.isNotEmpty && groupDescription.isNotEmpty) {
      final groupService = GroupService(ref.read(secureStorageProvider));
      bool success = await groupService.saveGroup(
        name: groupName,
        description: groupDescription,
        members: selectedMembers,
        admins: selectedAdmins,
        imageFile: _imageFile != null ? File(_imageFile!.path) : null,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('성공적으로 생성 완료하였습니다. 모임에서 이벤트를 만들어보세요!')),
        );
        ref.read(clubStateProvider.notifier).fetchClubs(); // 클럽 리스트 다시 불러오기
        Navigator.of(context).pop(); // 성공 시 페이지 닫기
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('그룹을 생성하는 데 실패했습니다. 나중에 다시 시도해주세요.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('그룹 이름과 설명을 입력해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(secureStorageProvider);
    final UserService userService = UserService(storage);

    final userAccount = ref.watch(userAccountProvider);  // userAccount 상태를 감시

    if (userAccount == null) {
      return const Center(child: CircularProgressIndicator());  // 로딩 중일 때
    }
    print("=====userAccount1: $userAccount");

    // 사용자 정보를 멤버와 관리자에 추가
    if (!selectedMembers.any((member) => member.userId == userAccount.userId)) {
      selectedMembers.add(GetAllUserProfile(
        id: userAccount.id,
        userId: userAccount.userId,
        profileImage: userAccount.profileImage ?? '',
        name: userAccount.name,
      ));

      selectedAdmins.add(GetAllUserProfile(
        id: userAccount.id,
        userId: userAccount.userId,
        profileImage: userAccount.profileImage ?? '',
        name: userAccount.name,
      ));
    }

    print("=====userAccount2: $userAccount");

    // 화면 렌더링
    return Scaffold(
      appBar: AppBar(
        title: Text('모임 생성'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    _imageFile != null
                        ? CircleAvatar(
                      radius: 50,
                      backgroundImage: FileImage(File(_imageFile!.path)),
                    )
                        : Icon(Icons.camera_alt, size: 100, color: Colors.grey),
                    TextButton(
                      onPressed: _pickImage,
                      child: Text('사진 추가'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  hintText: '새로운 모임의 이름을 입력해주세요.',
                  hintStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              TextField(
                controller: _groupDescriptionController,
                decoration: InputDecoration(
                  hintText: '모임의 소개 문구를 작성해주세요.',
                  border: InputBorder.none,
                ),
              ),
              SizedBox(height: 20),

              // + 멤버 추가 버튼
              MemberAddButton(onPressed: () => _showMemberDialog(false)),

              // 추가된 멤버 목록 표시
              if (selectedMembers.isNotEmpty) ...[
                SizedBox(height: 10),
                Text("추가된 멤버"),
                MemberInvite(selectedMembers: selectedMembers),
              ],

              SizedBox(height: 20),

              // + 관리자 추가 버튼
              AdminAddButton(onPressed: () => _showMemberDialog(true)),

              // 추가된 관리자 목록 표시
              if (selectedAdmins.isNotEmpty) ...[
                SizedBox(height: 10),
                Text("추가된 관리자"),
                MemberInvite(selectedMembers: selectedAdmins),
              ],

              SizedBox(height: 20),
              const Text(
                '※ 모임을 생성하는 사람은 모임 멤버이자 관리자로 설정됩니다.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const Text(
                '※ 모임명, 소개 문구, 멤버, 관리자를 모두 설정한 후 완료 버튼을 눌러주세요',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _onComplete,
                  child: Text('완료'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
