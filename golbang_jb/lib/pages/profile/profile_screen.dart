import 'package:flutter/material.dart';
import 'package:golbang/pages/profile/statistics_page.dart';
import 'statistics_page.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profile header
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const Text(
            'iNES 님',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          // Action buttons
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.8, // 조정된 비율
              children: [
                _buildActionButton(context, '지난 기록', Icons.history, () {
                  // 지난 기록 버튼 클릭시 동작 추가
                }),
                _buildActionButton(context, '통계', Icons.bar_chart, () {
                  // 통계 버튼 클릭 시 StatisticsPage로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StatisticsPage(), // StatisticsPage로 수정
                    ),
                  );
                }),
                _buildActionButton(context, '소속된 그룹', Icons.group, () {
                  // 소속된 그룹 버튼 클릭시 동작 추가
                }),
                _buildActionButton(context, '관리 그룹', Icons.admin_panel_settings, () {
                  // 관리 그룹 버튼 클릭시 동작 추가
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.green,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
