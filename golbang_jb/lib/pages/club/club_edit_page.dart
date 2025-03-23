import 'dart:io';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/pages/club/widgets/admin_button_widget.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/group.dart';
import '../../models/member.dart';
import '../../models/user_account.dart';
import '../../provider/club/club_state_provider.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/club_service.dart';
import '../../widgets/sections/admin_invite.dart';
import '../../widgets/sections/member_dialog.dart';
import '../profile/profile_screen.dart';
import 'club_main.dart';

class ClubEditPage extends ConsumerStatefulWidget {
  final Group club; // 모임 ID를 받도록 수정
  const ClubEditPage({super.key, required this. club});

  @override
  _ClubEditPageState createState() => _ClubEditPageState();
}

class _ClubEditPageState extends ConsumerState<ClubEditPage> {
  List<Member> selectedAdmins = [];
  List<Member> membersWithoutMe= [];
  late TextEditingController _groupNameController;
  late TextEditingController _groupDescriptionController;
  late UserAccount? userAccount;
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
    _groupNameController = TextEditingController(text: widget.club.name ?? '');
    _groupDescriptionController = TextEditingController(text: widget.club.description ?? '');
    log('membersWithoutMe: ${membersWithoutMe.length}');
    selectedAdmins = widget.club.members.where((m) => m.role == "admin").toList();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(userAccountProvider.notifier).loadUserAccount();  // 상태 업데이트만 진행
      final user = ref.read(userAccountProvider);
      setState(() {
        userAccount = user;
        membersWithoutMe = widget.club.members
            .where((m) => m.accountId != userAccount?.id)
            .toList();
      });
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
      if (result != null) {
        setState(() {
            selectedAdmins = result;
        });
      }
    });
  }

  void _onComplete() async {
    String groupName = _groupNameController.text.isNotEmpty
        ? _groupNameController.text : widget.club.name;
    String groupDescription = _groupDescriptionController.text.isNotEmpty
        ? _groupDescriptionController.text : widget.club.description ?? '';

    if (groupName.isNotEmpty && groupDescription.isNotEmpty) {
      final clubService = ClubService(ref.read(secureStorageProvider));
      bool success = await clubService.updateClubWithAdmins(
        clubId: widget.club.id,
        name: groupName,
        description: groupDescription,
        adminIds: selectedAdmins.map((e)=> e.memberId).toList(),
        imageFile: _imageFile != null ? File(_imageFile!.path) : null,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('성공적으로 수정하였습니다.')),
        );
        ref.read(clubStateProvider.notifier).fetchClubs(); // 클럽 리스트 다시 불러오기
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ClubMainPage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모임을 수정하는 데 실패했습니다. 나중에 다시 시도해주세요.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모임 이름과 설명을 입력해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 렌더링
    return Scaffold(
      appBar: AppBar(
        title: const Text('모임 수정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _imageFile != null
                          ? FileImage(File(_imageFile!.path))
                          : (widget.club.image.startsWith('http')
                          ? NetworkImage(widget.club.image)
                          : null) as ImageProvider<Object>?,
                      child: (_imageFile == null && !widget.club.image.startsWith('http'))
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
                  hintText: widget.club.name,
                  hintStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              TextField(
                controller: _groupDescriptionController,
                decoration: InputDecoration(
                  hintText: widget.club.description ?? '모임의 소개 문구를 작성해주세요.',
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
                  onPressed: _onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('완료'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
