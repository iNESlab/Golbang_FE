import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/club.dart';
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
      print('클럽 목록 불러오기 실패: $e');
    }
  }

  // 클럽을 선택하는 함수
  void selectClub(Club club) {
    state = state.copyWith(selectedClub: club);
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
