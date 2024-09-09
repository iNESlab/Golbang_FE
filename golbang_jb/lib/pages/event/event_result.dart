import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/pages/event/widgets/team_result.dart';
import 'package:golbang/pages/event/widgets/user_profile.dart';
import 'package:golbang/services/event_service.dart';
import 'package:golbang/pages/event/widgets/event_header.dart';
import 'package:golbang/pages/event/widgets/mini_score_card.dart';
import 'package:golbang/pages/event/widgets/ranking_list.dart';

import '../../models/participant.dart';
import '../../models/user_profile.dart';
import '../../repoisitory/secure_storage.dart';

class EventResultPage extends ConsumerStatefulWidget {
  final int eventId;

  const EventResultPage({Key? key, required this.eventId}) : super(key: key);

  @override
  _EventResultPageState createState() => _EventResultPageState();
}

class _EventResultPageState extends ConsumerState<EventResultPage> {
  UserProfile? _userProfile;
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

    final individualData = await eventService.getIndividualResults(widget.eventId);
    final teamData = await eventService.getTeamResults(widget.eventId);

    if (individualData != null && teamData != null) {
      // Check if this is a team event by inspecting the team_type of participants
      _isTeamEvent = individualData['participants'].any((participant) => participant['team_type'] != 'NONE');

      setState(() {
        _userProfile = UserProfile.fromJson(individualData['user']);
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
        title: Text("이벤트 전체 결과"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      backgroundColor: Colors.grey[200],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _eventData == null
          ? Center(child: Text("데이터를 불러오지 못했습니다."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventHeader(
              eventTitle: _eventData!['event_title'],
              location: _eventData!['location'],
              startDateTime: DateTime.parse(_eventData!['start_date_time']),
              endDateTime: DateTime.parse(_eventData!['end_date_time']),
              gameMode: _eventData!['game_mode'],
              participantCount: _eventData!['participants'].length.toString(),
              myGroupType: _eventData!['group_type'].toString(),
              isHandicapEnabled: _isHandicapEnabled,
              onHandicapToggle: (value) {
                setState(() {
                  _isHandicapEnabled = value;
                });
              },
            ),
            SizedBox(height: 10),
            UserProfileWidget(
              userProfile: _isHandicapEnabled
                  ? UserProfile.fromJson({
                ..._eventData!['user'],
                'sum_score': _eventData!['user']['handicap_score'],
                'rank': _eventData!['user']['handicap_rank'],
              })
                  : _userProfile!,
            ),
            SizedBox(height: 10),
            if (_isTeamEvent) ...[
              TeamResultWidget(
                teamAGroupWins: _isHandicapEnabled
                    ? _teamResultData!['group_scores']['team_a_group_wins_handicap']
                    : _teamResultData!['group_scores']['team_a_group_wins'],
                teamBGroupWins: _isHandicapEnabled
                    ? _teamResultData!['group_scores']['team_b_group_wins_handicap']
                    : _teamResultData!['group_scores']['team_b_group_wins'],
                groupWinTeam: _isHandicapEnabled
                    ? _teamResultData!['group_scores']['group_win_team_handicap']
                    : _teamResultData!['group_scores']['group_win_team'],
                teamATotalScore: _isHandicapEnabled
                    ? _teamResultData!['total_scores']['team_a_total_score_handicap']
                    : _teamResultData!['total_scores']['team_a_total_score'],
                teamBTotalScore: _isHandicapEnabled
                    ? _teamResultData!['total_scores']['team_b_total_score_handicap']
                    : _teamResultData!['total_scores']['team_b_total_score'],
                totalWinTeam: _isHandicapEnabled
                    ? _teamResultData!['total_scores']['total_win_team_handicap']
                    : _teamResultData!['total_scores']['total_win_team'],
              ),
            ],
            SizedBox(height: 10),
            MiniScoreCard(
              scorecard: _isHandicapEnabled
                  ? List<int>.from(_eventData!['user']['handicap_scorecard'])
                  : _userProfile!.scorecard,
            ),
            SizedBox(height: 10),
            Text("Ranking", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            RankingList(
              participants: _eventData!['participants'].map<Participant>((participantJson) {
                return Participant.fromJson(participantJson).copyWith(
                  sumScore: _isHandicapEnabled
                      ? participantJson['handicap_score']
                      : participantJson['sum_score'],
                  rank: _isHandicapEnabled
                      ? participantJson['handicap_rank']
                      : participantJson['rank'],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
