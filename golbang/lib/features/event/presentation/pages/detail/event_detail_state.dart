import 'dart:async';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:golbang/models/event.dart';
import 'package:golbang/repoisitory/secure_storage.dart';

import '../../../utils/reponsive_utils.dart';

mixin EventDetailStateMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  Event? event;
  LatLng? selectedLocation;
  int? myGroup;
  late Timer timer;
  late DateTime currentTime;
  late DateTime startDateTime;
  late DateTime endDateTime;
  late final int myParticipantId;
  late final String myStatus;

  List<dynamic> participants = [];
  Map<String, dynamic>? teamAScores;
  Map<String, dynamic>? teamBScores;
  bool isLoading = true;

  late double fontSizeXLarge;
  late double fontSizeLarge;
  late double fontSizeMedium;
  late double fontSizeSmall;
  late Orientation orientation;
  late double screenWidth;


  Future<void> fetchEvent(int eventId) async {
    final storage = ref.read(secureStorageProvider);
    final eventService = EventService(storage);
    try {
      final fetchedEvent = await eventService.getEventDetails(eventId);
      if (mounted && fetchedEvent != null) {
        setState(() {
          event = fetchedEvent;
          initializeFields();
          fetchScores();
        });
      } else {
        if (mounted) context.pop();
      }
    } catch (e) {
      log('Error fetching event details: $e');
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void initializeUI(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    orientation = MediaQuery.of(context).orientation;

    fontSizeXLarge = ResponsiveUtils.getXLargeFontSize(screenWidth, orientation);
    fontSizeLarge = ResponsiveUtils.getLargeFontSize(screenWidth, orientation);
    fontSizeMedium = ResponsiveUtils.getMediumFontSize(screenWidth, orientation);
    fontSizeSmall = ResponsiveUtils.getSmallFontSize(screenWidth, orientation);
  }


  void initializeFields() {
    startDateTime = event!.startDateTime;
    endDateTime = event!.endDateTime;
    myParticipantId = event!.myParticipantId;
    myStatus = event!.participants.firstWhere((p) => p.participantId == myParticipantId).statusType;
    selectedLocation = _parseLocation(event!.location);
    myGroup = event!.memberGroup;
    currentTime = DateTime.now();
  }

  Future<void> fetchScores() async {
    if (event == null) return;

    final storage = ref.watch(secureStorageProvider);
    final eventService = EventService(storage);
    try {
      final response = await eventService.getScoreData(event!.eventId);
      if (response != null) {
        setState(() {
          participants = response['participants'];
          teamAScores = response['team_a_scores'];
          teamBScores = response['team_b_scores'];
          isLoading = false;
        });
      } else {
        log('Failed to load scores: response is null');
      }
    } catch (error) {
      log('Error fetching scores: $error');
    }
  }

  LatLng? _parseLocation(String? location) {
    if (location == null) return null;
    try {
      if (location.startsWith('LatLng')) {
        final coords = location
            .substring(7, location.length - 1)
            .split(',')
            .map((e) => double.parse(e.trim()))
            .toList();
        return LatLng(coords[0], coords[1]);
      }
    } catch (_) {}
    return null;
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        currentTime = DateTime.now();
      });
    });
  }

  void disposeTimer() {
    timer.cancel();
  }
}
