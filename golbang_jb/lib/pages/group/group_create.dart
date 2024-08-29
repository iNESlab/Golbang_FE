import 'package:flutter/material.dart';
import 'package:golbang/global_config.dart';
import 'package:golbang/api.dart';
import 'package:golbang/widgets/sections/member_dialog.dart';
import 'package:golbang/widgets/sections/member_invite.dart';

import '../../models/user.dart';

class GroupCreatePage extends StatefulWidget {
  @override
  _GroupCreatePageState createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends State<GroupCreatePage> {

  List<String> selectedMembers = [];
  TextEditingController _groupNameController = TextEditingController();
  TextEditingController _groupDescriptionController = TextEditingController();

  User? user = getUserByToken(users, 'token_john_doe');

  void _showMemberDialog() {
    showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return MemberDialog(
          selectedMembers: selectedMembers,
          onMembersSelected: (List<String> members) {
            setState(() {
              selectedMembers = members;
            });
          },
        );
      },
    ).then((result) {
      if (result != null) {
        setState(() {
          selectedMembers = List<String>.from(result);
        });
      }
    });
  }

  void _onComplete() {
    String groupName = _groupNameController.text;
    String groupDescription = _groupDescriptionController.text;
    if (groupName.isNotEmpty && groupDescription.isNotEmpty) {
      addGroup(groupName, 'assets/images/apple.png');
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('그룹 이름과 설명을 입력해주세요.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    Icon(Icons.camera_alt, size: 100, color: Colors.grey),
                    TextButton(
                      onPressed: () {
                        // 사진 추가 버튼 클릭시 동작
                      },
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
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: AssetImage('assets/images/apple.png'),
                ),
                title: Text(user!.username),
                trailing: IconButton(
                  icon: Icon(Icons.arrow_forward_ios, color: Colors.green),
                  onPressed: _showMemberDialog,
                ),
              ),
              SizedBox(height: 20),
              Text(
                '멤버 초대',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
