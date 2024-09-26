import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/pages/group/widgets/admin_button_widget.dart';
import 'package:golbang/services/user_service.dart';
import 'package:golbang/widgets/sections/member_dialog.dart';
import 'package:golbang/widgets/sections/member_invite.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/profile/get_event_result_participants_ranks.dart';
import '../../provider/club/club_state_provider.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/group_service.dart';

class GroupCreatePage extends ConsumerStatefulWidget {
  @override
  _GroupCreatePageState createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends ConsumerState<GroupCreatePage> {
  List<GetEventResultParticipantsRanks> selectedAdmins = [];
  List<GetEventResultParticipantsRanks> selectedMembers = [];
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


  void _showMemberDialog(List<GetEventResultParticipantsRanks> users) {
    showDialog<List<GetEventResultParticipantsRanks>>(
      context: context,
      builder: (BuildContext context) {
        return MemberDialog(
          selectedMembers: users,
          onMembersSelected: (List<GetEventResultParticipantsRanks> members) {
            setState(() {
              selectedMembers = members;
            });
          },
        );
      },
    ).then((result) {
      if (result != null) {
        setState(() {
          if(users == selectedMembers){
            selectedMembers = result;
            selectedAdmins.removeWhere((admin) =>
                selectedMembers.contains(admin)
            );
          }
          else if(users == selectedAdmins){
            selectedAdmins = result;
            selectedMembers.removeWhere((member) =>
                selectedAdmins.contains(member)
            );
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
        // 클럽 생성 성공 후 상태 업데이트
        ref.read(clubStateProvider.notifier).fetchClubs(); // 클럽 리스트 다시 불러오기
        Navigator.of(context).pop(); // 성공 시 페이지 닫기
      } else {
        // 실패 시 기본 에러 메시지 표시
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
              const Text(
                '내 프로필',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              FutureBuilder<GetEventResultParticipantsRanks>(
                future: userService.getUserProfile(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('프로필을 불러오는데 실패했습니다.'));
                  } else if (snapshot.hasData) {
                    final userProfile = snapshot.data!;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: userProfile.profileImage.startsWith('http')
                            ? NetworkImage(userProfile.profileImage)
                            : AssetImage(userProfile.profileImage) as ImageProvider,
                      ),
                      title: Text(userProfile.name),
                      trailing: IconButton(
                        icon: Icon(Icons.arrow_forward_ios, color: Colors.green),
                        onPressed: () => _showMemberDialog(selectedMembers),
                      ),
                    );
                  } else {
                    return Center(child: Text('프로필이 없습니다.'));
                  }
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: AdminAddButton(onPressed: ()=>_showMemberDialog(selectedAdmins)),
                  ),
                  Expanded(
                    child: MemberInvite(selectedMembers: selectedAdmins),
                  ),
                ],
              ),
              MemberInvite(selectedMembers: selectedMembers),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _onComplete,
                  child: Text('완료'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
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