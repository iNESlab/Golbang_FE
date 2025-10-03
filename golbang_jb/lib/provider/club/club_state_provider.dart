import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/club.dart';
import '../../models/member.dart';
import '../../services/club_service.dart';
import 'club_service_provider.dart';

// ClubStateNotifier: 클럽 리스트와 선택된 클럽 상태를 관리
final clubStateProvider = StateNotifierProvider<ClubStateNotifier, ClubState>((ref) {
  final clubService = ref.watch(clubServiceProvider);
  return ClubStateNotifier(clubService);
});

class ClubStateNotifier extends StateNotifier<ClubState> {
  final ClubService _clubService;

  ClubStateNotifier(this._clubService) : super(ClubState());

  // 클럽 리스트를 불러와 상태로 설정
  Future<void> fetchClubs() async {
    try {
      final clubs = await _clubService.getMyClubList();
      
      // 🔧 수정: 빈 배열 체크 추가
      if (clubs.isNotEmpty) {
        log('club[0] length: ${clubs[0].members.length}');
        log('🔍 fetchClubs: club[0].unreadCount=${clubs[0].unreadCount}');
        log('🔍 fetchClubs: club[0].name=${clubs[0].name}');
      } else {
        log('🔍 fetchClubs: 클럽 목록이 비어있음');
      }
      
      // selectedClub 초기화
      state = state.copyWith(
        clubList: clubs,
        selectedClub: null,
      );
      
      log('🔍 fetchClubs: state 업데이트 완료, clubList.length=${state.clubList.length}');
    } catch (e) {
      log('클럽 목록 불러오기 실패: $e');
    }
  }


  // 클럽 리스트를 불러와 상태로 설정
  Future<void> getClub(int clubId, BuildContext context) async {
    try {
      final club = await _clubService.getClub(clubId: clubId);
      // selectedClub 초기화
      state = state.copyWith(
        clubList: [
          ...state.clubList.where((c) => c.id != clubId), // 기존 같은 ID 제거
          club!, // 새로운 club 추가
        ],
        selectedClub: club,
      );
    } catch (e) {
      log('클럽 목록 불러오기 실패: $e');
      if (!mounted) return; // context 사용 전에 반드시 mounted 체크
      context.pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 클럽을 선택하는 함수
  void selectClubById(int clubId) {
    final club = state.clubList.firstWhere(
          (c) => c.id == clubId,
      orElse: () => throw Exception("클럽 ID를 clubList에서 찾을 수 없습니다."),
    );

    state = state.copyWith(selectedClub: club);
  }


  void updateSelectedClubMembers(List<Member> newMembers) {
    final currentClub = state.selectedClub;
    if (currentClub != null) {
      log('updateInviteMembers1 : ${currentClub.members.length}');
      log('newMembers : ${newMembers.length}');
      final updatedClub = currentClub.copyWith(
        members: [...currentClub.members, ...newMembers],
      );

      log('updateInviteMembers2 : ${currentClub.members.length}');
      state = state.copyWith(selectedClub: updatedClub);
    }
  }

  void removeMemberFromSelectedClub(int memberId) {
    final currentClub = state.selectedClub;
    if (currentClub != null) {
      log('memberId: $memberId');
      log('updateRemoveMembers1 : ${currentClub.members.length}');
      final updatedMembers = currentClub.members
          .where((m) => m.memberId != memberId)
          .toList();

      log('updateRemoveMembers2 : ${updatedMembers.length}');

      final updatedClub = currentClub.copyWith(members: updatedMembers);
      state = state.copyWith(selectedClub: updatedClub);
    }
  }

  void removeClub(int clubId) {
    final updatedList = state.clubList.where((c) => c.id != clubId).toList();
    state = state.copyWith(clubList: updatedList);

    // 선택된 클럽도 삭제된 클럽이면 null로
    if (state.selectedClub?.id == clubId) {
      state = state.copyWith(selectedClub: null);
    }
  }

}

class ClubState {
  final List<Club> clubList;
  final Club? selectedClub;

  ClubState({this.clubList = const [], this.selectedClub});

  ClubState copyWith({List<Club>? clubList, Club? selectedClub}) {
    return ClubState(
      clubList: clubList ?? this.clubList,
      selectedClub: selectedClub ?? this.selectedClub,
    );
  }
}
