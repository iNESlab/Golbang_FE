// lib/pages/event/detail/event_detail_page.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/event.dart';
import 'event_detail_appbar.dart';
import 'event_detail_body.dart';
import 'event_detail_bottom.dart';
import 'event_detail_state.dart';

class EventDetailPage extends ConsumerStatefulWidget {
  final int? eventId;
  final Event? event;
  final String? from;

  const EventDetailPage({
    super.key,
    this.eventId,
    this.event,
    this.from
  });

  @override
  EventDetailPageState createState() => EventDetailPageState();
}

class EventDetailPageState extends ConsumerState<EventDetailPage> with EventDetailStateMixin {
  @override
  void initState() {
    super.initState();
    log('check1');
    // ① 이벤트 초기화 (event or eventId)
    if (widget.event != null) {
      log('check2');

      event = widget.event;
      initializeFields();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await fetchScores(); // 내부에서 setState를 통해 isLoading = false 처리됨
      });

    } else if (widget.eventId != null) {
      log('check3: ${widget.eventId}');
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await fetchEvent(widget.eventId!);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.pop();
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
      context.go('/events');
    }
  }


  @override
  Widget build(BuildContext context) {
    log('loading: $isLoading');
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    initializeUI(context);

    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          await handleBack();
        },
        child: Scaffold(
        appBar: buildEventDetailAppBar(context, ref, event!, currentTime, startDateTime, endDateTime),
        body: SingleChildScrollView(
          child: SafeArea(
    child: EventDetailBody(
            event: event!,
              fontSizeXLarge: fontSizeXLarge,
              fontSizeLarge: fontSizeLarge,
              fontSizeMedium: fontSizeMedium,
              fontSizeSmall: fontSizeSmall,
              selectedLocation: selectedLocation,
              startDateTime: startDateTime,
              endDateTime: endDateTime,
              myGroup: myGroup,
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
          myStatus: myStatus,
          currentTime: currentTime,
          startDateTime: startDateTime,
          endDateTime: endDateTime,
        ),
      ),
    )
    );
  }
}
