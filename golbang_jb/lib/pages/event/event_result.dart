import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:golbang/pages/event/widgets/team_result.dart';
import 'package:golbang/pages/event/widgets/user_profile.dart';
import 'package:golbang/services/event_service.dart';
import 'package:golbang/pages/event/widgets/event_header.dart';
import 'package:golbang/pages/event/widgets/mini_score_card.dart';
import 'package:golbang/pages/event/widgets/ranking_list.dart';

import '../../models/participant.dart';
import '../../models/profile/get_event_result_participants_ranks.dart';
import '../../repoisitory/secure_storage.dart';

class EventResultPage extends ConsumerStatefulWidget {
  final int eventId;

  const EventResultPage({super.key, required this.eventId});

  @override
  _EventResultPageState createState() => _EventResultPageState();
}

class _EventResultPageState extends ConsumerState<EventResultPage> {
  GetEventResultParticipantsRanks? _userProfile;
  Map<String, dynamic>? _eventData;
  Map<String, dynamic>? _teamResultData;
  bool _isLoading = true;
  bool _isHandicapEnabled = false;
  bool _isTeamEvent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEventResults();
  }

  Future<void> _loadEventResults() async {
    final storage = ref.watch(secureStorageProvider);
    final eventService = EventService(storage);

    // 토글On->핸디캡 순으로 정렬된 데이터를 가져오도록 sortType을 설정 / 토글Off->핸디캡 NULL
    final individualData = await eventService.getIndividualResults(
      widget.eventId,
      sortType: _isHandicapEnabled ? 'handicap_score' : null,
    );
    final teamData = await eventService.getTeamResults(
      widget.eventId,
      sortType: _isHandicapEnabled ? 'handicap_score' : null,
    );

    if (individualData != null && teamData != null) {
      _isTeamEvent = individualData['participants'].any((participant) => participant['team_type'] != 'NONE');

      setState(() {
        _userProfile = GetEventResultParticipantsRanks.fromJson(individualData['user']);
        _eventData = individualData;
        _teamResultData = teamData;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _eventData = null;
        _teamResultData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("이벤트 전체 결과"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop()
        ),
      ),
      backgroundColor: Colors.grey[200],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _eventData == null
          ? const Center(child: Text("데이터를 불러오지 못했습니다."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventHeader(
              eventTitle: _eventData!['event_title'],
              location: _eventData!['site'],
              startDateTime: DateTime.parse(_eventData!['start_date_time']),
              endDateTime: DateTime.parse(_eventData!['end_date_time']),
              gameMode: _eventData!['game_mode'],
              participantCount: _eventData!['participants'].length.toString(),
              myGroupType: _eventData!['group_type'].toString(),
              isHandicapEnabled: _isHandicapEnabled,
              onHandicapToggle: (value) {
                setState(() {
                  _isHandicapEnabled = value;
                  _isLoading = true;
                });
                _loadEventResults(); // 데이터를 다시 로드
              },
            ),
            const SizedBox(height: 10),
            UserProfileWidget(
              userProfile: _isHandicapEnabled
                  ? GetEventResultParticipantsRanks.fromJson({
                ..._eventData!['user'],
                'sum_score': _eventData!['user']['handicap_score'] ?? _eventData!['user']['sum_score'], // null 체크 추가
                'rank': _eventData!['user']['handicap_rank'] ?? _eventData!['user']['rank'], // null 체크 추가
              })
                  : _userProfile!,
            ),
            const SizedBox(height: 10),
            if (_isTeamEvent) ...[
              TeamResultWidget(
                teamAGroupWins: _isHandicapEnabled
                    ? _teamResultData!['group_scores']['team_a_group_wins_handicap'] ?? 0 // null 체크 추가
                    : _teamResultData!['group_scores']['team_a_group_wins'] ?? 0, // null 체크 추가
                teamBGroupWins: _isHandicapEnabled
                    ? _teamResultData!['group_scores']['team_b_group_wins_handicap'] ?? 0 // null 체크 추가
                    : _teamResultData!['group_scores']['team_b_group_wins'] ?? 0, // null 체크 추가
                groupWinTeam: _isHandicapEnabled
                    ? _teamResultData!['group_scores']['group_win_team_handicap'] ?? 'N/A' // null 체크 추가
                    : _teamResultData!['group_scores']['group_win_team'] ?? 'N/A', // null 체크 추가
                teamATotalStroke: _isHandicapEnabled
                    ? _teamResultData!['total_scores']['team_a_total_score_handicap'] ?? 0 // null 체크 추가
                    : _teamResultData!['total_scores']['team_a_total_score'] ?? 0, // null 체크 추가
                teamBTotalStroke: _isHandicapEnabled
                    ? _teamResultData!['total_scores']['team_b_total_score_handicap'] ?? 0 // null 체크 추가
                    : _teamResultData!['total_scores']['team_b_total_score'] ?? 0, // null 체크 추가
                totalWinTeam: _isHandicapEnabled
                    ? _teamResultData!['total_scores']['total_win_team_handicap'] ?? 'N/A' // null 체크 추가
                    : _teamResultData!['total_scores']['total_win_team'] ?? 'N/A', // null 체크 추가
              ),
            ],
            const SizedBox(height: 10),
            MiniScoreCard(
              scorecard: _isHandicapEnabled && _eventData!['user']['handicap_scorecard'] != null
                  ? List<int>.from(_eventData!['user']['handicap_scorecard'] ?? []) // null 체크 추가
                  : _userProfile?.scorecard ?? [], // null 체크 추가
              eventId: widget.eventId,
            ),
            const SizedBox(height: 10),
            RankingList(
              participants: _eventData!['participants'] != null
                  ? _eventData!['participants'].map<Participant>((participantJson) {
                return Participant.fromJson(participantJson).copyWith(
                  sumScore: _isHandicapEnabled
                      ? participantJson['handicap_score'] ?? participantJson['sum_score'] // null 체크 추가
                      : participantJson['sum_score'],
                  rank: _isHandicapEnabled
                      ? participantJson['handicap_rank'] ?? participantJson['rank'] // null 체크 추가
                      : participantJson['rank'],
                );
              }).toList()
                  : [], // 만약 null이라면 빈 리스트를 반환
            ),
          ],
        ),
      ),
    );
  }
}