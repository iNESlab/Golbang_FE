// lib/pages/event/detail/event_detail_page.dart
import 'dart:developer';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../provider/event/event_state_notifier_provider.dart';
import 'event_detail_appbar.dart';
import 'event_detail_body.dart';
import 'event_detail_bottom.dart';
import 'event_detail_state.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  final int eventId;
  final String? from;

  const EventDetailPage({
    super.key,
    required this.eventId,
    this.from
  });

  @override
  EventDetailPageState createState() => EventDetailPageState();
}

class EventDetailPageState extends ConsumerState<EventDetailPage> with EventDetailStateMixin {
  @override
  void initState() {
    super.initState();
    // ① 이벤트 초기화 (event or eventId)
    // ① 상태에서 먼저 이벤트 찾기
    final notifier = ref.read(eventStateNotifierProvider.notifier);
    final existing = notifier.getEventFromState(widget.eventId);

    if (existing != null) {
      // 상태에 있으면 바로 사용
      setState(() {
        event = existing;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await fetchScores(); // 점수는 따로 불러와야 하니까 호출
      });
    } else {
      // 상태에 없으면 API 호출 (딥링크 케이스)
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await  notifier.fetchEventDetails(widget.eventId);
      });
      setState(() {
        isLoading = false;
      });
    }
    // ② 현재 시간 업데이트 타이머 시작
    startTimer();
  }

  @override
  void dispose() {
    disposeTimer(); // 타이머 정리
    super.dispose();
  }

  Future<void> handleBack() async {
    if(!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/app/events');
    }
  }


  @override
  Widget build(BuildContext context) {
    log('loading: $isLoading');
    final eventState = ref.watch(eventStateNotifierProvider);
    event = eventState.eventsByDay.values
        .expand((list) => list)
        .firstWhereOrNull((e) => e.eventId == widget.eventId);

    if (event == null || isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    initializeUI(context);

    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          await handleBack();
        },
        child: Scaffold(
        appBar: buildEventDetailAppBar(context, ref, event!, currentTime, participants),
        body: SingleChildScrollView(
          child: SafeArea(
    child: EventDetailBody(
            event: event!,
              fontSizeXLarge: fontSizeXLarge,
              fontSizeLarge: fontSizeLarge,
              fontSizeMedium: fontSizeMedium,
              fontSizeSmall: fontSizeSmall,
              selectedLocation: parseLocation(event!.location),
              startDateTime: event!.startDateTime,
              endDateTime: event!.endDateTime,
              myGroup: event!.memberGroup,
              orientation: orientation,
              screenWidth: screenWidth,
              participants: event!.participants,
            ),
        ),
        ),

      bottomNavigationBar: SafeArea(
        top: false, bottom: true, // 하단만 보호
        child: EventDetailBottomBar( // 위젯 안에 ElevatedButton을 넣어야 SafeArea와의 여백이 안생김
          event: event!,
          myStatus: event!.participants.firstWhere((p) => p.participantId == event!.myParticipantId).statusType,
          currentTime: currentTime,
          startDateTime: event!.startDateTime,
          endDateTime: event!.endDateTime,
        ),
      ),
    )
    );
  }
}
