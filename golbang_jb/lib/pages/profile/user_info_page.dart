import 'dart:io'; // 추가
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_account.dart'; // models/user_account.dart에서 UserAccount 클래스를 가져옵니다.

class UserInfoPage extends StatefulWidget {
  final UserAccount userAccount;

  UserInfoPage({required this.userAccount});

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('내 정보'),
        actions: [
          TextButton(
            onPressed: () {
              // 확인 버튼을 눌렀을 때의 동작
            },
            child: const Text(
              '확인',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          Center(
            child: GestureDetector(
              onTap: _pickImage, // 프로필 이미지를 클릭하면 이미지 선택창이 열림
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.transparent,
                backgroundImage: _imageFile != null
                    ? FileImage(File(_imageFile!.path))
                    : (widget.userAccount.profileImage != null
                    ? NetworkImage(widget.userAccount.profileImage!) as ImageProvider
                    : AssetImage('assets/default_profile.png')),
                child: _imageFile == null && widget.userAccount.profileImage == null
                    ? Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: TextButton(
              onPressed: _pickImage, // "프로필 이미지 변경" 텍스트를 누르면 이미지 선택창이 열림
              child: const Text(
                '프로필 이미지 변경',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            title: const Text('아이디'),
            subtitle: Text(widget.userAccount.userId),
          ),
          ListTile(
            title: const Text('이름'),
            subtitle: Text(widget.userAccount.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showEditDialog(context, '이름', widget.userAccount.name);
            },
          ),
          ListTile(
            title: const Text('이메일'),
            subtitle: Text(widget.userAccount.email),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showEditDialog(context, '이메일', widget.userAccount.email);
            },
          ),
          ListTile(
            title: const Text('연락처'),
            subtitle: Text(widget.userAccount.phoneNumber),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showEditDialog(context, '연락처', widget.userAccount.phoneNumber);
            },
          ),
          ListTile(
            title: const Text('핸디캡'),
            subtitle: Text(widget.userAccount.handicap.toString()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showEditDialog(context, '핸디캡', widget.userAccount.handicap.toString());
            },
          ),
          ListTile(
            title: const Text('집 주소'),
            subtitle: Text(widget.userAccount.address),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showEditDialog(context, '집 주소', widget.userAccount.address);
            },
          ),
          ListTile(
            title: const Text('생일'),
            subtitle: Text(widget.userAccount.dateOfBirth != null
                ? '${widget.userAccount.dateOfBirth!.year}년 ${widget.userAccount.dateOfBirth!.month}월 ${widget.userAccount.dateOfBirth!.day}일'
                : '입력되지 않음'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showDatePicker(context, '생일', widget.userAccount.dateOfBirth);
            },
          ),
          ListTile(
            title: const Text('학번'),
            subtitle: Text(widget.userAccount.studentId ?? '입력되지 않음'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showEditDialog(context, '학번', widget.userAccount.studentId ?? '');
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '* 대학 동문회 모임을 위해 필요한 경우 입력 바랍니다',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
      // bottomNavigationBar 설정 삭제
    );
  }

  void _showEditDialog(BuildContext context, String field, String value) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$field 수정'),
          content: TextField(
            controller: TextEditingController(text: value),
            decoration: InputDecoration(hintText: '새로운 $field 입력'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                // 새로운 값을 저장하는 로직
                Navigator.of(context).pop();
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _showDatePicker(BuildContext context, String field, DateTime? initialDate) {
    showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate != null) {
        // 생일을 저장하는 로직 추가
        print('Selected date: $pickedDate');
      }
    });
  }
}
