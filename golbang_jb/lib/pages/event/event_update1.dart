import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/club.dart';
import '../../models/enum/event.dart';
import '../../models/event.dart';
import '../../models/member.dart';
import '../../models/profile/member_profile.dart';
import '../../models/responseDTO/GolfClubResponseDTO.dart';
import '../../models/responseDTO/CourseResopnseDTO.dart';
import '../../repoisitory/secure_storage.dart';
import '../../services/club_service.dart';
import 'widgets/location_search_dialog.dart';
import 'widgets/course_selection_dialog.dart';
import 'widgets/participant_dialog.dart';
import 'event_update2.dart';

class EventsUpdate1 extends ConsumerStatefulWidget {
  final Event event; // 기존 이벤트 데이터를 받아오기 위한 필드

  const EventsUpdate1({super.key, required this.event});

  @override
  _EventsUpdate1State createState() => _EventsUpdate1State();
}

class _EventsUpdate1State extends ConsumerState<EventsUpdate1> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  List<Club> _clubs = [];
  Club? _selectedClub;
  GameMode? _selectedGameMode;
  List<ClubMemberProfile> _selectedParticipants = [];
  late ClubService _clubService;
  bool _isButtonEnabled = true;

  GoogleMapController? _mapController;

  LatLng? _selectedLocation;
  late String _site;  // 선택된 장소의 이름을 저장하는 변수
  
  // 골프장과 코스 선택 관련 변수들
  GolfClubResponseDTO? _selectedGolfClub;
  CourseResponseDTO? _selectedCourse;

  @override
  void initState() {
    super.initState();
    _site = widget.event.site;
    _clubService = ClubService(ref.read(secureStorageProvider));
    _fetchClubs();
    _setupInitialValues(); // 전달받은 이벤트 데이터를 초기화하는 메서드
    _setupListeners();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // TimeOfDay.format을 안전하게 호출하기 위해 didChangeDependencies에서 설정
    final startTime = TimeOfDay.fromDateTime(widget.event.startDateTime.toLocal());
    setState(() {
      _startTimeController.text = startTime.format(context);
    });
  }

  void _setupInitialValues() {
    // 전달받은 이벤트 데이터를 각 컨트롤러와 변수에 초기화
    _titleController.text = widget.event.eventTitle;
    _locationController.text = widget.event.site ?? '';
    _startDateController.text = widget.event.startDateTime.toLocal().toIso8601String().split('T').first;
    _startTimeController.text = widget.event.startDateTime.toLocal().toIso8601String().split('T').last;
    _selectedLocation = _parseLocation(widget.event.location);
    _selectedGameMode = GameMode.values.firstWhere((mode) => mode.value == widget.event.gameMode);
    _selectedParticipants = widget.event.participants.map((participant) {
      final member = participant.member;
      return ClubMemberProfile(
        memberId: member?.memberId ?? 0,
        name: member?.name ?? 'Unknown',
        profileImage: member?.profileImage ?? '',
        role: member?.role ?? 'member',
        accountId: member?.memberId ?? 0,
      );
    }).toList();
    
    // 골프장과 코스 정보 초기화
    if (widget.event.golfClub != null) {
      _selectedGolfClub = widget.event.golfClub;
    }
    if (widget.event.golfCourse != null) {
      _selectedCourse = widget.event.golfCourse;
    }
  }

  LatLng? _parseLocation(String? location) {
    if (location == null) {
      return null;
    }

    try {
      if (location.startsWith('LatLng')) {
        final coords = location
            .substring(7, location.length - 1)
            .split(',')
            .map((e) => double.parse(e.trim()))
            .toList();
        return LatLng(coords[0], coords[1]);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  void _setupListeners() {
    _titleController.addListener(_validateForm);
    _startDateController.addListener(_validateForm);
  }

  void _validateForm() {
    final isValid = _titleController.text.isNotEmpty &&
        _startDateController.text.isNotEmpty &&
        _selectedParticipants.isNotEmpty &&
        _selectedLocation != null &&
        _selectedClub != null &&
        _selectedGameMode != null &&
        _selectedGolfClub != null &&
        _selectedCourse != null;

    setState(() {
      _isButtonEnabled = isValid;
    });
  }

  Future<void> _fetchClubs() async {
    try {
      List<Club> clubs = await _clubService.getClubList();
      log('clubs: $clubs');
      setState(() {
        _clubs = clubs;
        _selectedClub = clubs.firstWhere(
              (club) => club.id == widget.event.club!.clubId,
          orElse: () => clubs.first,
        );
        log('selected club: $_selectedClub');
        _validateForm();
      });
    } catch (e) {
      log("Failed to load clubs: $e");
    }
  }

  void _showLocationSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => LocationSearchDialog(
        locationController: _locationController,
        onLocationSelected: (GolfClubResponseDTO site) {
          setState(() {
            _selectedGolfClub = site;
            _site = site.golfClubName;
            _selectedLocation = LatLng(site.latitude, site.longitude);
            _selectedCourse = null; // 골프장이 변경되면 코스 선택 초기화
            
            // 지도 컨트롤러가 존재하면 새로운 위치로 카메라 이동
            if (_mapController != null && _selectedLocation != null) {
              _mapController!.animateCamera(
                CameraUpdate.newLatLng(_selectedLocation!),
              );
            }

            _validateForm();
          });
        },
      ),
    );
  }

  void _showCourseSelectionDialog() {
    if (_selectedGolfClub == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 골프장을 선택해주세요.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => CourseSelectionDialog(
        golfClubId: _selectedGolfClub!.golfClubId,
        golfClubName: _selectedGolfClub!.golfClubName,
        onCourseSelected: (CourseResponseDTO course) {
          setState(() {
            _selectedCourse = course;
            _validateForm();
          });
        },
      ),
    );
  }


  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        final formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
        _startDateController.text = formattedDate;
        
        _validateForm();
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        _startTimeController.text = pickedTime.format(context);
      });
      _validateForm();
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  TimeOfDay _parseTimeOfDay(String time) {
    // 공백 제거 및 입력 문자열 정리
    time = time.trim();

    // 한국어 형식 처리: "오전 6:00" 또는 "오후 6:00"
    if (time.startsWith('오전') || time.startsWith('오후')) {
      final isPM = time.startsWith('오후'); // 오후 여부 확인
      final timeParts = time.replaceFirst(RegExp(r'오전|오후'), '').trim(); // "오전" 또는 "오후" 제거

      final timeOfDayParts = timeParts.split(':'); // "6:00" -> ["6", "00"]
      if (timeOfDayParts.length != 2) {
        throw FormatException('Invalid time format: $time'); // 형식 오류
      }

      final hour = int.parse(timeOfDayParts[0]);
      final minute = int.parse(timeOfDayParts[1]);

      return TimeOfDay(
        hour: isPM ? (hour == 12 ? 12 : hour + 12) : (hour == 12 ? 0 : hour),
        minute: minute,
      );
    }

    // 영어 형식 처리: "6:00 AM" 또는 "6:00 PM"
    final timeParts = time.split(' '); // "6:00 AM" -> ["6:00", "AM"]
    if (timeParts.length != 2) {
      throw FormatException('Invalid time format: $time'); // 형식 오류
    }

    final timeOfDayParts = timeParts[0].split(':'); // "6:00" -> ["6", "00"]
    if (timeOfDayParts.length != 2) {
      throw FormatException('Invalid time format: $time'); // 형식 오류
    }

    final hour = int.parse(timeOfDayParts[0]);
    final minute = int.parse(timeOfDayParts[1]);
    final isPM = timeParts[1].toLowerCase() == 'pm';

    return TimeOfDay(
      hour: isPM ? (hour == 12 ? 12 : hour + 12) : (hour == 12 ? 0 : hour),
      minute: minute,
    );
  }


  void _showParticipantDialog() {
    showDialog(
      context: context,
      builder: (context) => ParticipantDialog(
        selectedParticipants: _selectedParticipants,
        clubId: _selectedClub?.id ?? 0,
      ),
    ).then((result) {
      if (result != null) {
        setState(() {
          _selectedParticipants = List<ClubMemberProfile>.from(result);
        });
        _validateForm();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이벤트 수정'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '이벤트 제목',
                  hintText: '제목을 입력해주세요',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Club>(
                decoration: InputDecoration(
                  labelText: '모임 선택',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                value: _selectedClub,
                onChanged: (Club? value) {
                  setState(() {
                    _selectedClub = value;
                    _selectedParticipants = []; // 클럽 변경 시 참여자 초기화
                  });
                  _validateForm();
                },
                items: _clubs.map<DropdownMenuItem<Club>>((Club club) {
                  return DropdownMenuItem<Club>(
                    value: club,
                    child: Text(club.name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('골프장 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showLocationSearchDialog,
                child: AbsorbPointer(
                  child: TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: '골프장',
                      hintText: '골프장을 선택해주세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedGolfClub != null) ...[
                GestureDetector(
                  onTap: _showCourseSelectionDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.golf_course, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedCourse != null
                                ? '${_selectedCourse!.golfCourseName} (${_selectedCourse!.holes}홀, 파 ${_selectedCourse!.par})'
                                : '+ 코스 선택',
                            style: const TextStyle(color: Colors.black),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      '골프장을 선택한 후 코스를 선택해주세요',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
              if (_selectedLocation != null) const SizedBox(height: 16),
              if (_selectedLocation != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _selectedLocation!,
                      zoom: 14.0,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('selected-location'),
                        position: _selectedLocation!,
                      ),
                    },
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller; // 컨트롤러 저장
                    },
                  ),
                ),
              const SizedBox(height: 16),
              const Text('시간', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context, true),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _startDateController,
                          decoration: InputDecoration(
                            labelText: '시작 날짜',
                            hintText: '날짜 선택',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(context, true),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _startTimeController,
                          decoration: InputDecoration(
                            labelText: '시작 시간',
                            hintText: '시간 선택',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            prefixIcon: const Icon(Icons.access_time),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    '이벤트 종료 날짜는 시작 날짜로부터 1일 후로 자동 설정됩니다',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('참여자', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _selectedClub != null ? _showParticipantDialog : null, // 클럽이 선택되지 않았으면 비활성화
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: _selectedClub != null ? Colors.grey : Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8.0),
                    color: _selectedClub != null ? Colors.white : Colors.grey[200],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_add, color: _selectedClub != null ? Colors.grey : Colors.grey[300]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedParticipants.isEmpty
                              ? '+ 참여자 추가'
                              : _selectedParticipants.map((p) => p.name).join(', '),
                          style: const TextStyle(color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('게임모드', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<GameMode>(
                decoration: const InputDecoration(
                  labelText: '게임모드',
                  border: OutlineInputBorder(),
                ),
                value: _selectedGameMode, // value를 GameMode 타입으로 설정
                onChanged: (newValue) {
                  setState(() {
                    _selectedGameMode = newValue!;
                    _validateForm();
                  });
                },
                items: GameMode.values.map((mode) {
                  return DropdownMenuItem<GameMode>(
                    value: mode,
                    child: Text(
                      mode == GameMode.STROKE ? '스트로크' : mode.toString(),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _isButtonEnabled
                      ? () {
                    _validateForm();
                    if (!_isButtonEnabled) return;

                    final DateTime startDate = DateTime.parse(_startDateController.text);
                    final TimeOfDay startTime = _parseTimeOfDay(_startTimeController.text);
                    final DateTime startDateTime = _combineDateAndTime(startDate, startTime);
                    final DateTime endDateTime = startDateTime.add(const Duration(days: 1));

                    // 로그 추가
                    log('startDateTime: $startDateTime');
                    log('endDateTime: $endDateTime');
                    log('Duration in days: ${endDateTime.difference(startDateTime).inDays}');
                    log('Duration in hours: ${endDateTime.difference(startDateTime).inHours}');

                    // 업데이트할 이벤트 데이터를 EventsUpdate2로 전달
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventsUpdate2(
                          eventId: widget.event.eventId,
                          title: _titleController.text,
                          selectedClub: _selectedClub!,
                          selectedLocation: _selectedLocation!,
                          selectedGolfClub: _selectedGolfClub!,
                          selectedCourse: _selectedCourse!,
                          startDate: startDateTime,
                          endDate: endDateTime,
                          selectedParticipants: _selectedParticipants,
                          existingParticipants: widget.event.participants.where((p) {
                            Member member = p.member!;

                            // selectedParticipants에 해당 memberId가 있는지 확인
                            return _selectedParticipants.any((participant) =>
                            participant.memberId == member.memberId
                            );
                          }).toList(),
                          selectedGameMode: _selectedGameMode!,
                        ),
                      ),
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: _isButtonEnabled ? Colors.white : Colors.black54,
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: _isButtonEnabled ? Colors.teal : Colors.grey,
                  ),
                  child: const Text('다음'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}