import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:golbang/pages/event/widgets/team_result.dart';
import 'package:golbang/pages/event/widgets/user_profile.dart';
import 'package:golbang/features/event/data/datasources/event_remote_ds.dart';
import 'package:golbang/pages/event/widgets/event_header.dart';
import 'package:golbang/pages/event/widgets/mini_score_card.dart';
import 'package:golbang/pages/event/widgets/ranking_list.dart';

import '../../../features/event/domain/entities/participant.dart';
import '../../../models/profile/get_event_result_participants_ranks.dart';
import '../../../features/event/data/models/golf_course_detail_response_dto.dart';
import '../../../repoisitory/secure_storage.dart';

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
  CourseResponseDTO? _golfClubResponseDTO;
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
        _golfClubResponseDTO = CourseResponseDTO.fromJson(individualData['golf_course']);
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
      bottomNavigationBar: SafeArea(
        top: true, bottom: true,
        child: ElevatedButton(
          onPressed: _showTeePickerAndNavigate, // ← 여기만 교체
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            foregroundColor: Colors.white,
            backgroundColor: Colors.teal,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: const Text('신페리온 계산하기'),
        ),
      ),
    );
  }


  Future<void> _showTeePickerAndNavigate() async {
    final tees = _golfClubResponseDTO?.tees ?? [];
    if (tees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tee 정보가 없습니다.')),
      );
      return;
    }

    final uniqueTees = _mergeSamePars(tees);

    // 바텀시트로 티 선택 UI 표시
    final selected = await showModalBottomSheet<TeeResponseDTO>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text('Tee 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: uniqueTees.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final tee = uniqueTees[i];
                    final pars = tee.holePars.take(18).join(','); // 프리뷰(앞 9개)
                    return ListTile(
                      title: Text(tee.teeName),
                      subtitle: Text('Pars: $pars'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => ctx.pop(tee),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    log('pars: ${selected.holePars}');

    // 선택된 티의 pars 검증
    final parsed = _parseParsOrNull(selected.holePars);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('선택한 티(${selected.teeName})의 Par 데이터가 올바르지 않습니다. (18개 숫자 필요)')),
      );
      return;
    }

    final qs = _buildParQuery(parsed);
    log('qs: $qs');

    context.push('/app/new-peoria?$qs');
  }

  List<TeeResponseDTO> _mergeSamePars(List<TeeResponseDTO> tees) {
    final grouped = <String, List<TeeResponseDTO>>{};

    for (final tee in tees) {
      // Pars를 비교 키로 사용 (문자열로 합쳐서 비교)
      final key = tee.holePars.join(',');
      grouped.putIfAbsent(key, () => []).add(tee);
    }

    final merged = <TeeResponseDTO>[];
    grouped.forEach((parsKey, teeGroup) {
      String mergedName;
      if (teeGroup.length > 2) {
        // 2개 이상이면 앞 2개 + ...
        mergedName = '${teeGroup[0].teeName} / ${teeGroup[1].teeName} / ...';
      } else {
        mergedName = teeGroup.map((t) => t.teeName).join(' / ');
      }

      merged.add(TeeResponseDTO(
        teeName: mergedName,
        holePars: teeGroup.first.holePars,
        holeHandicaps: teeGroup.first.holeHandicaps,
      ));
    });

    return merged;
  }


// pars 문자열 리스트가 18개이고 모두 숫자인지 검증 + float 문자열 허용
  List<int>? _parseParsOrNull(List<String> pars) {
    if (pars.length != 18) return null;
    final out = <int>[];
    for (final s in pars) {
      final v = int.tryParse(s.trim());
      if (v == null) return null;
      out.add(v);
    }
    return out;
  }

// 쿼리스트링 만들기 (백엔드가 par=4&par=5... 도, par=4,5,... 도 둘 다 지원한다면 한 가지로 고정)
  String _buildParQuery(List<int> pars) {
    // 반복 키 방식: ?par=4&par=4&par=5...
    final segments = pars.map((p) => 'par=${Uri.encodeQueryComponent(p.toString())}').join('&');
    return segments;
    // CSV로 하고 싶으면:
    // return 'par=${Uri.encodeQueryComponent(pars.join(','))}';
  }

}