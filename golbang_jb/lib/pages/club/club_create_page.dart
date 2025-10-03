import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:golbang/pages/club/widgets/admin_button_widget.dart';
import 'package:golbang/pages/club/widgets/member_button_widget.dart';
import 'package:golbang/widgets/sections/user_dialog.dart';
import 'package:golbang/widgets/sections/member_invite.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/profile/get_all_user_profile.dart';
import '../../provider/club/club_state_provider.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/group_service.dart';
import '../profile/profile_screen.dart';

class ClubCreatePage extends ConsumerStatefulWidget {
  const ClubCreatePage({super.key});

  @override
  _ClubCreatePageState createState() => _ClubCreatePageState();
}

class _ClubCreatePageState extends ConsumerState<ClubCreatePage> {
  List<GetAllUserProfile> selectedAdminUsers = [];
  List<GetAllUserProfile> selectedUsers = [];
  int userId = 0;
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();
  XFile? _imageFile;
  bool _isLoading = false; // 🔧 추가: 로딩 상태

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
        return UserDialog(
          selectedMembers: selectedUsers, // 여기에 항상 selectedMembers를 전달
          isAdminMode: isAdminMode,
          selectedAdmins: selectedAdminUsers,
        );
      },
    ).then((result) {
      if (result != null) {
        setState(() {
          if (isAdminMode) {
            selectedAdminUsers = result;
          } else {
            selectedUsers = result;
          }
        });
      }
    });
  }

  void _onComplete() async {
    String groupName = _groupNameController.text;
    String groupDescription = _groupDescriptionController.text; // 빈 문자열 허용

    if (groupName.isNotEmpty) {
      setState(() => _isLoading = true); // 🔧 추가: 로딩 시작
      
      try {
        final groupService = GroupService(ref.read(secureStorageProvider));
        bool success = await groupService.saveGroup(
          name: groupName,
          description: groupDescription, // 입력하지 않으면 빈 문자열
          members: selectedUsers,
          admins: selectedAdminUsers,
          imageFile: _imageFile != null ? File(_imageFile!.path) : null,
          currentUserId: userId,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('성공적으로 생성 완료하였습니다.')),
          );
          ref.read(clubStateProvider.notifier).fetchClubs(); // 클럽 리스트 다시 불러오기
          context.pop(); // 성공 시 페이지 닫기
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('그룹을 생성하는 데 실패했습니다. 나중에 다시 시도해주세요.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false); // 🔧 추가: 로딩 종료
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹 이름을 입력해주세요.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final userAccount = ref.watch(userAccountProvider);  // userAccount 상태를 감시

    if (userAccount == null) {
      return const Center(child: CircularProgressIndicator());  // 로딩 중일 때
    }
    // 사용자 정보를 멤버와 관리자에 추가
    if (!selectedUsers.any((user) => user.userId == userAccount.userId)) {
      selectedUsers.add(GetAllUserProfile(
        accountId: userAccount.id,
        userId: userAccount.userId,
        profileImage: userAccount.profileImage ?? '',
        name: userAccount.name,
      ));

      selectedAdminUsers.add(GetAllUserProfile(
        accountId: userAccount.id,
        userId: userAccount.userId,
        profileImage: userAccount.profileImage ?? '',
        name: userAccount.name,
      ));
    }
    // 화면 렌더링
    return Scaffold(
      appBar: AppBar(
        title: const Text('모임 생성'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
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
                        : const Icon(Icons.camera_alt, size: 100, color: Colors.grey),
                    TextButton(
                      onPressed: _pickImage,
                      child: const Text('사진 추가'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  hintText: '새로운 모임의 이름을 입력해주세요.',
                  hintStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              TextField(
                controller: _groupDescriptionController,
                decoration: const InputDecoration(
                  hintText: '모임의 소개 문구를 작성해주세요.(선택)',
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 20),

              // + 멤버 추가 버튼
              MemberAddButton(onPressed: () => _showMemberDialog(false)),

              // 추가된 멤버 목록 표시
              if (selectedUsers.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text("추가된 멤버"),
                MemberInvite(selectedMembers: selectedUsers),
              ],

              const SizedBox(height: 20),

              // + 관리자 추가 버튼
              AdminAddButton(onPressed: () => _showMemberDialog(true)),

              // 추가된 관리자 목록 표시
              if (selectedAdminUsers.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text("추가된 관리자"),
                MemberInvite(selectedMembers: selectedAdminUsers),
              ],

              const SizedBox(height: 20),
              const Text(
                '※ 모임을 생성하는 사람은 모임 멤버이자 관리자로 설정됩니다.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const Text(
                '※ 모임명, 멤버, 관리자를 모두 설정한 후 완료 버튼을 눌러주세요',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onComplete, // 🔧 추가: 로딩 중 버튼 비활성화
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading 
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 10),
                          Text('생성 중...'),
                        ],
                      )
                    : const Text('완료'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
