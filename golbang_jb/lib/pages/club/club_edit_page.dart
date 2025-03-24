import 'dart:io';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
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
import '../home/home_page.dart';
import '../profile/profile_screen.dart';

class ClubEditPage extends ConsumerStatefulWidget {
  final Club club;

  const ClubEditPage({
    Key? key,
    required this.club,
  }) : super(key: key);

  @override
  _ClubEditPageState createState() => _ClubEditPageState();
}

class _ClubEditPageState extends ConsumerState<ClubEditPage> {
  late Club _club;
  late UserAccount userAccount;

  List<Member> selectedAdmins = [];
  List<Member> membersWithoutMe= [];
  late final TextEditingController _groupNameController;
  late final TextEditingController _groupDescriptionController;
  XFile? _imageFile;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _club = widget.club;
    _groupNameController = TextEditingController();
    _groupDescriptionController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Provider에서 선택된 클럽과 사용자 정보를 가져옴
    final club = ref.watch(clubStateProvider.select((s) => s.selectedClub));
    final user = ref.watch(userAccountProvider);

    // club이 null이 아니고, 아직 _club에 세팅 안 했다면 한번만 세팅
    if (club != null && user != null) {
      setState(() {
        _club = club;
        userAccount = user;

        // 초기값 세팅
        membersWithoutMe = club.members.where((m) => m.accountId != user.id).toList();
        selectedAdmins = club.members.where((m) => m.role == 'admin').toList();

        // TextEditingController에 값 할당
        _groupNameController.text = club.name;
        _groupDescriptionController.text = club.description ?? '';
      });
    }
  }

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
        : _club.name;
    // 설명은 사용자가 입력한 그대로 사용
    String groupDescription = _groupDescriptionController.text;

    if (groupName.isNotEmpty) {
      final clubService = ClubService(ref.read(secureStorageProvider));
      bool success = await clubService.updateClubWithAdmins(
        clubId: _club.id,
        name: groupName,
        description: groupDescription,
        adminIds: selectedAdmins.map((e) => e.memberId).toList(),
        imageFile: _imageFile != null ? File(_imageFile!.path) : null,
      );

      if (success) {
        //TODO: 상태 저장해야함
        // ref.read(clubStateProvider.notifier).selectClub(club);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('성공적으로 수정하였습니다.')),
        );
        //TODO: 초기 페이지로 이동하지 않아도 되게 향후 수정해야함.
        ref.read(clubStateProvider.notifier).fetchClubs(); // 클럽 리스트 다시 불러오기
        Get.offAll(() => const HomePage(), arguments: {
          'initialIndex': 2,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모임을 수정하는 데 실패했습니다. 나중에 다시 시도해주세요.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모임 이름을 입력해주세요.')),
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
                          : (_club.image.startsWith('http')
                          ? NetworkImage(_club.image)
                          : null) as ImageProvider<Object>?,
                      child: (_imageFile == null && !_club.image.startsWith('http'))
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
                  hintText: _club.name,
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
