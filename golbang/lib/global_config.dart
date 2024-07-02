import 'models/bookmark.dart';
import 'models/event.dart';
import 'models/group.dart';

const String testEmail = 'test@example.com';
const String testPassword = 'password123';
const String testOTP = '1234';

class GlobalConfig {
  static const List<Bookmark> bookmarks = [
    Bookmark('내 프로필', '-15.9', 'G핸디'),
    Bookmark('스코어', '72(-1)', 'Par-Tee Time', '23.02.12'),
    Bookmark('기록', '100', '99등', '23.02.07'),
  ];

  static const List<Event> events = [
    Event('Event 1', 'Group 1', '12:00 PM', 'Location 1', 10, 'Group A', '완료',
        '참석', true),
    Event('Event 2', 'Group 2', '2:00 PM', 'Location 2', 20, 'Group B', '미납',
        '불참', false),
    Event('Event 3', 'Group 3', '3:00 PM', 'Location 3', 30, 'Group C', '완료',
        '미정', true),
    Event('Event 3', 'Group 3', '3:00 PM', 'Location 3', 30, 'Group C', '완료',
        '미정', true),
    Event('Event 3', 'Group 3', '3:00 PM', 'Location 3', 30, 'Group C', '완료',
        '미정', true),
  ];

  static const List<Group> groups = [
    Group('Group 1', true),
    Group('Group 2', false),
    Group('Group 3', true),
    Group('Group 4', false),
    Group('Group 5', true),
  ];

  static List<Map<String, String>> groupData = [
    {
      'image': 'assets/images/google.png',
      'label': '가천대 동문',
    },
    {
      'image': 'assets/images/google.png',
      'label': 'INES',
    },
    {
      'image': 'assets/images/google.png',
      'label': '성남 북부신',
    },
    {
      'image': 'assets/images/google.png',
      'label': '골프에 미치다',
    },
    {
      'image': 'assets/images/google.png',
      'label': '파티타임',
    },
    {
      'image': 'assets/images/google.png',
      'label': 'A',
    },
  ];

  static List<Map<String, String>> announcementData = [
    {
      'title': '정수미',
      'date': '2024.03.07',
      'content': '[관리자 변경 안내] 가천대 동문 그룹 모임 관리자가 변경되었습니다.',
    },
    {
      'title': '김민정',
      'date': '2024.03.06',
      'content': '[회비 납부 안내] 회비 납부 계좌가 기존 시흥은행에서 가천은행으로 변경되었습니다.',
    },
    {
      'title': '이진우',
      'date': '2024.03.06',
      'content': '투표 결과 확인',
    },
  ];
}

