import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:golbang/global/PrivateClient.dart';

import '../../models/club.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/club_service.dart';
import '../../provider/club/club_state_provider.dart';

class ClubSearchPage extends ConsumerStatefulWidget {
  const ClubSearchPage({super.key});

  @override
  _ClubSearchPageState createState() => _ClubSearchPageState();
}

class _ClubSearchPageState extends ConsumerState<ClubSearchPage> {
  List<Club> searchResults = [];
  bool isLoading = false;
  bool isProcessing = false; // 🔧 추가: 신청/취소 처리 중 상태
  PrivateClient privateClient = PrivateClient();
  late ClubService clubService;
  int? accountId;

  @override
  void initState() {
    super.initState();
    final storage = ref.read(secureStorageProvider);
    clubService = ClubService(storage);
    _loadAccountId();
  }

  Future<void> _loadAccountId() async {
    final id = await privateClient.getAccountId();
    setState(() {
      accountId = id;
    });
  }

  Future<void> _searchClubs(String query) async {
    if (query.isEmpty) return;

    setState(() => isLoading = true);
    try {
      final results = await clubService.searchClubList(query);
      setState(() {
        searchResults = results ?? [];
        isLoading = false;
      });
    } catch (e) {
      log("Error searching clubs: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
      ));
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '모임 검색',
            border: InputBorder.none,
          ),
          onChanged: _searchClubs,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : searchResults.isEmpty
          ? const Center(child: Text("검색 결과가 없습니다."))
          : ListView.builder(
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          final club = searchResults[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: SizedBox(
                width: 40, // CircleAvatar와 같은 크기
                height: 40,
                child: club.image.startsWith('http')
                    ? CircleAvatar(
                  backgroundImage: NetworkImage(club.image),
                  radius: 20,
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(20), // CircleAvatar와 동일한 둥근 모양
                  child: Image.asset(
                    club.image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(
                club.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "관리자: ${_getAdminName(club)}",
              ),
              trailing: _buildActionButton(context, club),
            ),
          );
        },
      ),
    );
  }
  Widget _buildActionButton(BuildContext context, Club club) {
    // 현재 유저 멤버 객체 찾기
    final currentUser = accountId == null
        ? null
        : club.members.firstWhereOrNull((m) => m.accountId == accountId);

      if (currentUser != null) {
        if (currentUser.statusType == 'active') {
          // ✅ 이미 가입된 모임 → 이동 버튼
          return ElevatedButton(
            onPressed: () {
              // 상세 페이지로 이동
              context.push('/app/clubs/${club.id}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text("이동"),
          );
        } else if (currentUser.statusType == 'applied') {
          // ⏳ 신청함 → 취소 버튼
          return ElevatedButton(
            onPressed: isProcessing ? null : () => _cancelApplication(club),
            style: ElevatedButton.styleFrom(
              backgroundColor: isProcessing ? Colors.grey : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: isProcessing 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text("신청 취소"),
          );
        } else if (currentUser.statusType == 'invited') {
          // 📨 초대받음 → 수락/거절 버튼
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => _respondToInvitation(club, 'accepted'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text("수락"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _respondToInvitation(club, 'declined'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text("거절"),
              ),
            ],
          );
        }
      }

      // 🆕 가입 안 한 모임 → 신청 버튼
      return ElevatedButton(
        onPressed: isProcessing ? null : () async {
          setState(() {
            isProcessing = true;
          });
          try {
            await clubService.applyClub(club.id);
            
            // 🔧 추가: 신청 후 clubStateProvider 새로고침
            ref.read(clubStateProvider.notifier).fetchClubs();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("참가 신청이 완료되었습니다.")),
            );
            context.pop();
          } catch (e) {
            log("Error applying to club: $e");
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$e'),
                  backgroundColor: Colors.red,
                ));
          } finally {
            setState(() {
              isProcessing = false;
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isProcessing ? Colors.grey : Colors.green,
          foregroundColor: Colors.white,
        ),
        child: isProcessing 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text("신청"),
      );
    }

  // 🔧 추가: 초대 응답 처리
  Future<void> _respondToInvitation(Club club, String response) async {
    try {
      await clubService.respondInvitation(club.id, response);
      
      // 🔧 추가: 응답 후 clubStateProvider 새로고침
      ref.read(clubStateProvider.notifier).fetchClubs();
      
      if (response == 'accepted') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("초대를 수락했습니다. 클럽에 가입되었습니다."),
            backgroundColor: Colors.green,
          ),
        );
        // 클럽 상세 페이지로 이동
        context.push('/app/clubs/${club.id}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("초대를 거절했습니다."),
            backgroundColor: Colors.orange,
          ),
        );
        // 검색 결과 새로고침
        _searchClubs('');
      }
    } catch (e) {
      log("Error responding to invitation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('초대 응답 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🔧 추가: 신청 취소 처리
  Future<void> _cancelApplication(Club club) async {
    setState(() {
      isProcessing = true;
    });
    try {
      await clubService.cancelApplication(club.id);
      
      // 🔧 추가: 취소 후 clubStateProvider 새로고침
      ref.read(clubStateProvider.notifier).fetchClubs();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("신청이 취소되었습니다."),
          backgroundColor: Colors.orange,
        ),
      );
      // 🔧 추가: 취소 후 페이지 나가기
      context.pop();
    } catch (e) {
      log("Error canceling application: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('신청 취소 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  // 🔧 추가: 관리자 이름을 안전하게 가져오는 메서드
  String _getAdminName(Club club) {
    try {
      final admin = club.members.firstWhere((m) => m.role == 'admin');
      return admin.name;
    } catch (e) {
      return '알 수 없음';
    }
  }
}