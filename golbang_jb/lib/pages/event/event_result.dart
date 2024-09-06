/*
pages/event/event_result.dart
이벤트 전체 결과 조회 페이지
*/
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/services/event_service.dart';
import 'package:golbang/pages/event/widgets/event_header.dart';
import 'package:golbang/pages/event/widgets/mini_score_card.dart';
import 'package:golbang/pages/event/widgets/ranking_list.dart';

import '../../models/participant.dart';
import '../../repoisitory/secure_storage.dart';

class EventResultPage extends ConsumerStatefulWidget {
  final int eventId;

  const EventResultPage({Key? key, required this.eventId}) : super(key: key);

  @override
  _EventResultPageState createState() => _EventResultPageState();
}

class _EventResultPageState extends ConsumerState<EventResultPage> {
  Map<String, dynamic>? _eventData;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEventResult();
  }

  Future<void> _loadEventResult() async {
    final storage = ref.watch(secureStorageProvider);
    final eventService = EventService(storage);

    final data = await eventService.getIndividualResults(widget.eventId);

    if (data != null) {
      setState(() {
        _eventData = data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _eventData = null;  // API 요청이 실패했을 때 처리
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
              myGroupType: "A", // 기본값으로 설정 (그룹 타입 없음)
            ),
            SizedBox(height: 20),
            Text("Score Card", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ScoreCard(
              scorecard: List<int>.from(_eventData!['user']['scorecard']),
            ),
            SizedBox(height: 20),
            Text("Ranking", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            RankingList(
              participants: _eventData!['participants'].map<Map<String, String>>((participantJson) {
                Participant participant = Participant.fromJson(participantJson);
                return {
                  'rank': participant.rank,
                  'name': participant.member?.name ?? 'Unknown',
                  'stroke': participant.sumScore?.toString() ?? 'N/A',  // null 처리 추가
                };
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
