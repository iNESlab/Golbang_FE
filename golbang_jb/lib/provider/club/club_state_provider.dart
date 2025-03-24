import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final clubs = await _clubService.getClubList();
      state = state.copyWith(clubList: clubs);
    } catch (e) {
      log('클럽 목록 불러오기 실패: $e');
    }
  }

  // 클럽을 선택하는 함수
  void selectClub(Club club) {
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
