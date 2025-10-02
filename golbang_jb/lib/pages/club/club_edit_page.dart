import 'dart:io';
import 'dart:developer';

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/pages/club/widgets/admin_button_widget.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/club.dart';
import '../../models/member.dart';
import '../../models/user_account.dart';
import '../../provider/club/club_state_provider.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/club_service.dart';
import '../../widgets/sections/admin_invite.dart';
import '../../widgets/sections/member_dialog.dart';
import '../profile/profile_screen.dart';

class ClubEditPage extends ConsumerStatefulWidget {
  const ClubEditPage({super.key});

  @override
  _ClubEditPageState createState() => _ClubEditPageState();
}

class _ClubEditPageState extends ConsumerState<ClubEditPage> {
  Club? _club;
  UserAccount? userAccount;

  List<Member> selectedAdmins = [];
  List<Member> membersWithoutMe= [];
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupDescriptionController = TextEditingController();
  XFile? _imageFile;

  final ImagePicker _picker = ImagePicker();
  bool _isInitialized = true;
  bool _isLoading = false; // 🔧 추가: 로딩 상태


  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _imageFile = pickedFile;
    });
  }

  // `GetAllUserProfile`을 사용하는 멤버 다이얼로그
  void _showMemberDialog() {
    showDialog<List<Member>>(
      context: context,
      builder: (BuildContext context) {
        return MemberDialog(
          members: membersWithoutMe, // 여기에 항상 selectedMembers를 전달
          isAdminMode: true,
          selectedMembers: selectedAdmins,
        );
      },
    ).then((result) {
      log('result: $result');
      if (result != null) {
        setState(() {
          log('result2: $result');
          selectedAdmins = result;
        });
      }

    });
  }

  void _onComplete() async {
    String groupName = _groupNameController.text.isNotEmpty
        ? _groupNameController.text
        : _club!.name;
    // 설명은 사용자가 입력한 그대로 사용
    String groupDescription = _groupDescriptionController.text;

    if (groupName.isNotEmpty) {
      setState(() => _isLoading = true); // 🔧 추가: 로딩 시작
      
      try {
        final clubService = ClubService(ref.read(secureStorageProvider));
        bool success = await clubService.updateClubWithAdmins(
          clubId: _club!.id,
          name: groupName,
          description: groupDescription,
          adminIds: selectedAdmins.map((e) => e.memberId).toList(),
          imageFile: _imageFile != null ? File(_imageFile!.path) : null,
        );
        
        if (!mounted) return;
        
        if (success) {
          //TODO: 상태 저장해야함
          // ref.read(clubStateProvider.notifier).selectClub(club);
          context.go('/app/clubs/${_club!.id}?refresh=${DateTime.now().millisecondsSinceEpoch}');
          // 실제로 라우터에서 처리 안해도 새로고침 됨

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('성공적으로 수정하였습니다.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('모임을 수정하는 데 실패했습니다. 나중에 다시 시도해주세요.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류가 발생했습니다: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false); // 🔧 추가: 로딩 종료
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모임 이름을 입력해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final club = ref.watch(clubStateProvider.select((s) => s.selectedClub));
    final user = ref.watch(userAccountProvider);

    if (club == null || user == null) {
      return const Center(child: CircularProgressIndicator()); // ✅ club이 null이면 로딩
    }

    if (_isInitialized) {
      // ✅ 초기화 진행
      _club = club;
      userAccount = user;
      membersWithoutMe = club.members.where((m) => m.accountId != user.id).toList();
      selectedAdmins = club.members.where((m) => m.role == 'admin').toList();
      _groupNameController.text = club.name ?? '';
      _groupDescriptionController.text = club.description ?? '';
      _isInitialized = false;
    }
    // 화면 렌더링
    return Scaffold(
      appBar: AppBar(
        title: const Text('모임 수정'),
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
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _imageFile != null
                          ? FileImage(File(_imageFile!.path))
                          : (_club!.image.startsWith('http')
                          ? NetworkImage(_club!.image)
                          : null) as ImageProvider<Object>?,
                      child: (_imageFile == null && !_club!.image.startsWith('http'))
                          ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                          : null,
                    ),
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
                decoration: InputDecoration(
                  hintText: _club!.name,
                  hintStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              TextField(
                controller: _groupDescriptionController,
                decoration: const InputDecoration(
                  hintText: '모임의 소개 문구를 작성해주세요 (선택)',
                  border: InputBorder.none,
                ),

              ),
              const SizedBox(height: 20),

              // + 관리자 추가 버튼
              AdminAddButton(onPressed: () => _showMemberDialog()),

              // 추가된 관리자 목록 표시
              if (selectedAdmins.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text("관리자 목록"),
                AdminInvite(selectedMembers: selectedAdmins),
              ],

              const SizedBox(height: 20),
              const Text(
                '※ 모임명, 소개 문구, 멤버, 관리자를 다시 확인해주세요.',
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
                          Text('수정 중...'),
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