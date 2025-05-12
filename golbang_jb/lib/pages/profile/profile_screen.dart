import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_account.dart'; // 이 파일에서 모든 UserAccount를 참조합니다.
import '../../repoisitory/secure_storage.dart';
import 'user_info_page.dart';
import '../../services/user_service.dart';
import 'package:golbang/pages/profile/statistics_page.dart';

// UserAccount 상태를 관리하는 Provider 정의
final userAccountProvider = StateNotifierProvider<UserAccountNotifier, UserAccount?>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return UserAccountNotifier(UserService(storage));
});

class UserAccountNotifier extends StateNotifier<UserAccount?> {
  final UserService _userService;

  UserAccountNotifier(this._userService) : super(null) {
    loadUserAccount();  // 초기 로드
  }

  // 사용자 정보를 처음 로드하거나 강제 리로드 시 사용하는 메서드
  Future<void> loadUserAccount() async {
    try {
      final newUserAccount = await _userService.getUserInfo();

      // 기존 상태와 새로 불러온 사용자 정보를 비교
      if (_hasUserAccountChanged(newUserAccount)) {
        state = newUserAccount;  // 변경된 값이 있을 경우에만 상태 업데이트
        log("UserAccount updated: $newUserAccount");
      } else {
        log("UserAccount has not changed");
      }
    } catch (e) {
      log('Failed to load user profile: $e');
    }
  }

  // 새로운 값과 현재 상태를 비교하는 메서드
  bool _hasUserAccountChanged(UserAccount? newUserAccount) {
    if (state == null && newUserAccount != null) return true;  // 기존 상태가 null인 경우
    if (state == null || newUserAccount == null) return false;  // 둘 중 하나가 null이면 변경 없음

    // 프로필 이미지가 null이 되었는지, 다른 필드가 변경되었는지 비교
    return state!.name != newUserAccount.name ||
        state!.email != newUserAccount.email ||
        state!.phoneNumber != newUserAccount.phoneNumber ||
        state!.handicap != newUserAccount.handicap ||
        state!.address != newUserAccount.address ||
        state!.dateOfBirth != newUserAccount.dateOfBirth ||
        state!.studentId != newUserAccount.studentId ||
        _profileImageChanged(state!.profileImage, newUserAccount.profileImage);  // 프로필 이미지 변화 감지
  }

// 프로필 이미지가 null에서 null이 아닌 상태로, 또는 그 반대로 변경된 경우를 감지
  bool _profileImageChanged(String? oldImage, String? newImage) {
    if (oldImage == null && newImage != null) return true;  // 기존에 없었는데 새로 생긴 경우
    if (oldImage != null && newImage == null) return true;  // 기존에 있었는데 사라진 경우
    return oldImage != newImage;  // 그 외의 경우 단순 비교
  }

}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // userAccount 상태를 감지하여 UI 갱신
    final userAccount = ref.watch(userAccountProvider);
    final isLoading = userAccount == null;

    // 처음 로드될 때 loadUserAccount 호출
    if (isLoading) {
      ref.read(userAccountProvider.notifier).loadUserAccount(); // 처음 로드 시 정보 불러오기
    }

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
              backgroundImage: userAccount.profileImage != null
                  ? NetworkImage(userAccount.profileImage!)
                  : null,
              child: userAccount.profileImage == null
                  ? const Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              userAccount.name ?? '사용자',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5, // TODO: 소속된 그룹, 관리 그룹을 활성화할 때는 1.8 비율로 변경해야 함
                children: [
                  _buildActionButton('내 정보', Icons.person, context, userAccount, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserInfoPage(initialUserAccount: userAccount),
                      ),
                    ).then((_) {
                      // 돌아왔을 때 정보 업데이트
                      ref.read(userAccountProvider.notifier).loadUserAccount();
                    });
                                    }),
                  _buildActionButton('통계', Icons.bar_chart, context, userAccount, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StatisticsPage(),
                      ),
                    );
                  }),
                  // _buildActionButton('소속된 그룹', Icons.group, context, userAccount, () {
                  //   // 소속된 그룹 버튼 동작 추가
                  // }),
                  // _buildActionButton('관리 그룹', Icons.admin_panel_settings, context, userAccount, () {
                  //   // 관리 그룹 버튼 동작 추가
                  // }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, BuildContext context, UserAccount? userAccount, VoidCallback onTap) {
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
                    fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
