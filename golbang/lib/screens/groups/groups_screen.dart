import 'package:flutter/material.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '내 모임',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, color: Colors.green),
                  label: const Text('모임 생성',
                      style: TextStyle(color: Colors.green)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '모임명 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.green),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.green),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                groupBlock('가천대 동문', 'assets/images/dragon.jpeg'),
                groupBlock('INES', 'assets/images/dragon.jpeg'),
                groupBlock('성남 북정시', 'assets/images/dragon.jpeg'),
                groupBlock('골프에 미치다', 'assets/images/dragon.jpeg'),
                groupBlock('파티타임', 'assets/images/dragon.jpeg'),
                groupBlock('A', 'assets/images/dragon.jpeg'),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              '공지사항',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          notificationCard('정수미', '2024.03.07',
              '[관리자 변경 안내] 가천대 동문 골프 모임 관리자가 김민정에서 정수미로 변경되었습니다.'),
          notificationCard('김민정', '2024.03.06',
              '[회비 납부 안내] 회비 납부 계좌가 기존 신한은행 23304-01-014-123456 (김민정) 에서 기업은행...'),
          notificationCard('이진우', '2024.03.06', '투표 빨리 해라'),
          notificationCard('추가된 공지사항', '2024.03.05', '추가된 공지사항 내용입니다.'),
          notificationCard('더 많은 공지사항', '2024.03.04', '더 많은 공지사항 내용입니다.'),
        ],
      ),
    );
  }

  Widget groupBlock(String title, String imagePath) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget notificationCard(String name, String date, String message) {
    return Card(
      color: Colors.green[50],
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundImage: AssetImage('assets/images/dragon.jpeg'),
              radius: 20,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(date, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4.0),
                  Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
