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

class ClubSearchPage extends ConsumerStatefulWidget {
  const ClubSearchPage({super.key});

  @override
  _ClubSearchPageState createState() => _ClubSearchPageState();
}

class _ClubSearchPageState extends ConsumerState<ClubSearchPage> {
  List<Club> searchResults = [];
  bool isLoading = false;
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
                "관리자: ${club.members.firstWhere((m) => m.role == 'admin').name}",
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
        } else if (currentUser.statusType == 'pending') {
          // ⏳ 신청 대기 → 비활성화 버튼
          return ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
            child: const Text("신청"),
          );
        }
      }

      // 🆕 가입 안 한 모임 → 신청 버튼
      return ElevatedButton(
        onPressed: () async {
          try {
            await clubService.applyClub(club.id);
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
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        child: const Text("신청"),
      );
    }
}