import 'package:flutter/material.dart';
import 'package:golbang/global_config.dart';

class GroupsCreate1 extends StatelessWidget {
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
      body: Padding(
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
              decoration: InputDecoration(
                hintText: '새로운 모임의 이름을 입력해주세요.',
                hintStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            TextField(
              decoration: InputDecoration(
                hintText: '모임의 소개 문구를 작성해주세요.',
                border: InputBorder.none, // 언더라인을 없앰
              ),
            ),
            SizedBox(height: 20),
            const Text(
              '내 프로필',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage('assets/images/profile.png'), // 예시 이미지
              ),
              title: Text('박김정'),
            ),
            SizedBox(height: 20),
            Text(
              '멤버 초대',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundImage: AssetImage('assets/images/profile.png'), // 예시 이미지
              ),
              title: Text('박김정'),
              trailing: IconButton(
                icon: Icon(Icons.link),
                onPressed: () {
                  // 초대 링크 버튼 클릭시 동작
                },
              ),
            ),
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // 완료 버튼 클릭시 동작
                },
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
    );
  }
}