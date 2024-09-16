import 'package:flutter/material.dart';
import '../../models/user_account.dart'; // models/user_account.dart에서 UserAccount 클래스를 가져옵니다.

class UserInfoPage extends StatelessWidget {
  final UserAccount userAccount;

  UserInfoPage({required this.userAccount});

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
          ListTile(
            title: const Text('아이디'),
            subtitle: Text(userAccount.userId),
          ),
          ListTile(
            title: const Text('이름'),
            subtitle: Text(userAccount.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showEditDialog(context, '이름', userAccount.name);
            },
          ),
          ListTile(
            title: const Text('이메일'),
            subtitle: Text(userAccount.email),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showEditDialog(context, '이메일', userAccount.email);
            },
          ),
          ListTile(
            title: const Text('연락처'),
            subtitle: Text(userAccount.phoneNumber),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showEditDialog(context, '연락처', userAccount.phoneNumber);
            },
          ),
          ListTile(
            title: const Text('핸디캡 정보'),
            subtitle: Text(userAccount.handicap.toString()),
          ),
          ListTile(
            title: const Text('집 주소'),
            subtitle: Text(userAccount.address),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showEditDialog(context, '집 주소', userAccount.address);
            },
          ),
          ListTile(
            title: const Text('생일'),
            subtitle: Text(userAccount.dateOfBirth != null
                ? '${userAccount.dateOfBirth!.year}년 ${userAccount.dateOfBirth!.month}월 ${userAccount.dateOfBirth!.day}일'
                : '입력되지 않음'),
          ),
          ListTile(
            title: const Text('학번'),
            subtitle: Text(userAccount.studentId ?? '입력되지 않음'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showEditDialog(context, '학번', userAccount.studentId ?? '');
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
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: '모임',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: '이벤트',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '내 정보',
          ),
        ],
        currentIndex: 3, // '내 정보' 탭을 활성화
        onTap: (index) {
          // 네비게이션 바 아이템을 눌렀을 때의 동작
        },
      ),
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
}
