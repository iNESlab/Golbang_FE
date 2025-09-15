import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/provider/participant/participant_service_provider.dart';

import '../../models/participant.dart';
import '../../services/participant_service.dart';


final participantStateProvider = StateNotifierProvider<ParticipantStateNotifier, ParticipantState>((ref) {
  final participantService = ref.watch(participantServiceProvider);
  return ParticipantStateNotifier(participantService);
});

class ParticipantStateNotifier extends StateNotifier<ParticipantState> {
  final ParticipantService _participantService;

  ParticipantStateNotifier(this._participantService) : super(ParticipantState());


  // 참여자 상태 업데이트
  Future<void> updateParticipantStatus(int participantId, String statusType) async {
    try {
      final success = await _participantService.updateParticipantStatus(participantId, statusType);
      if (success) {
        state = state.copyWith(
          participantList: state.participantList.map((p) {
            if (p.participantId == participantId) {
              return p.copyWith(statusType: statusType);
            }
            return p;
          }).toList(),
        );
      }
    } catch (e) {
      log('참여자 상태 업데이트 실패: $e');
    }
  }
}

class ParticipantState {
  final List<Participant> participantList;

  ParticipantState({this.participantList = const []});

  ParticipantState copyWith({List<Participant>? participantList}) {
    return ParticipantState(
      participantList: participantList ?? this.participantList,
    );
  }
}
