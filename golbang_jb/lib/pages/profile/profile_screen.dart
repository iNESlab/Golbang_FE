import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_account.dart'; // 이 파일에서 모든 UserAccount를 참조합니다.
import '../../repoisitory/secure_storage.dart';
import 'user_info_page.dart';
import '../../services/user_service.dart';

// UserAccount 상태를 관리하는 Provider 정의
final userAccountProvider = StateNotifierProvider<UserAccountNotifier, UserAccount?>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return UserAccountNotifier(UserService(storage));
});

class UserAccountNotifier extends StateNotifier<UserAccount?> {
  final UserService _userService;

  UserAccountNotifier(this._userService) : super(null) {
    loadUserAccount();
  }

  Future<void> loadUserAccount() async {
    try {
      final userAccount = await _userService.getUserInfo();
      state = userAccount as UserAccount?;
    } catch (e) {
      print('Failed to load user profile: $e');
    }
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAccount = ref.watch(userAccountProvider);
    final isLoading = userAccount == null;

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              backgroundImage: userAccount?.profileImage != null
                  ? NetworkImage(userAccount!.profileImage!)
                  : null,
              child: userAccount?.profileImage == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              userAccount?.name ?? '사용자',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.8,
                children: [
                  _buildActionButton('내 정보', Icons.person, context, userAccount),
                  _buildActionButton('지난 기록', Icons.history, context, userAccount),
                  _buildActionButton('통계', Icons.bar_chart, context, userAccount),
                  _buildActionButton('소속된 그룹', Icons.group, context, userAccount),
                  _buildActionButton('관리 그룹', Icons.admin_panel_settings, context, userAccount),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, BuildContext context, UserAccount? userAccount) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.green,
      child: InkWell(
        onTap: () {
          if (title == '내 정보' && userAccount != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserInfoPage(initialUserAccount: userAccount),
              ),
            );
          }
        },
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
