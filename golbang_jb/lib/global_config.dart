import 'models/bookmark.dart';
import 'models/event.dart';
import 'models/group.dart';
import 'models/member.dart';
import 'models/post.dart';
import 'models/user.dart';

const String testEmail = 'test@example.com';
const String testPassword = 'password123';
const String testOTP = '1234';

class GlobalConfig {
  static List<Bookmark> bookmarks = [
    Bookmark('내 프로필', '-15.9', 'G핸디'),
    Bookmark('스코어', '72(-1)', 'Par-Tee Time', '23.02.12'),
    Bookmark('기록', '100', '99등', '23.02.07'),
  ];

  static List<Event> events = [
    Event('Event 1', 'Group 1', DateTime(2024, 8, 28, 12, 0), 'Location 1', 10, 'Group A', '완료', '참석', true),
    Event('Event 2', 'Group 2', DateTime(2024, 8, 28, 14, 0), 'Location 2', 20, 'Group B', '미납', '불참', false),
    Event('Event 3', 'Group 3', DateTime(2024, 9, 3, 15, 0), 'Location 3', 30, 'Group C', '완료', '미정', true),
    Event('Event 4', 'Group 3', DateTime(2024, 9, 4, 17, 0), 'Location 3', 30, 'Group C', '완료', '미정', true),
    Event('Event 5', 'Group 3', DateTime(2024, 9, 5, 9, 0), 'Location 3', 30, 'Group C', '완료', '미정', true),
  ];
}

List<User> users = [
  User(
    userId: 1,
    userToken: 'token_john_doe',
    username: 'john_doe',
    role: 'ROLE_USER',
    fullname: 'John Doe',
    email: 'john.doe@example.com',
    loginType: 'normal',
    provider: 'local',
    password: 'password123',
    mobile: '123-456-7890',
    address: '123 Main St, Anytown, USA',
    dateOfBirth: DateTime(1990, 1, 1),
    handicap: 'None',
    studentId: 'S12345678',
    profileImage: 'assets/images/apple.png',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    recentConnectionTime: DateTime.now(),
    releaseAt: DateTime.now().add(Duration(days: 365)),

  ),
  User(
    userId: 2,
    userToken: 'token_jane_doe',
    username: 'jane_doe',
    role: 'ROLE_USER',
    fullname: 'Jane Doe',
    email: 'jane.doe@example.com',
    loginType: 'normal',
    provider: 'local',
    password: 'password123',
    mobile: '987-654-3210',
    address: '456 Main St, Anytown, USA',
    dateOfBirth: DateTime(1992, 2, 2),
    handicap: 'None',
    studentId: 'S87654321',
    profileImage: 'assets/images/apple.png',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    recentConnectionTime: DateTime.now(),
    releaseAt: DateTime.now().add(Duration(days: 365)),
  ),
  User(
    userId: 3,
    userToken: 'token_jungbeom_ko',
    username: '고중범',
    role: 'ROLE_USER',
    fullname: '고중범',
    email: 'test@example.com',
    loginType: 'normal',
    provider: 'local',
    password: 'password123',
    mobile: '123-456-7890',
    address: '123 Main St, Anytown, USA',
    dateOfBirth: DateTime(1990, 1, 1),
    handicap: 'None',
    studentId: 'S12345678',
    profileImage: 'assets/images/apple.png',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    recentConnectionTime: DateTime.now(),
    releaseAt: DateTime.now().add(Duration(days: 365)),
  ),
  User(
    userId: 4,
    userToken: 'token_sumi_jung',
    username: '정수미',
    role: 'ROLE_USER',
    fullname: '정수미',
    email: 'wjdtnal@example.com',
    loginType: 'normal',
    provider: 'local',
    password: 'password123',
    mobile: '123-456-7890',
    address: '123 Main St, Anytown, USA',
    dateOfBirth: DateTime(1990, 1, 1),
    handicap: 'None',
    studentId: 'S12345678',
    profileImage: 'assets/images/apple.png',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    recentConnectionTime: DateTime.now(),
    releaseAt: DateTime.now().add(Duration(days: 365)),
  ),
];

List<Member> members = [
  Member(
    id: 1,
    groupId: 1,
    userId: 1,
    role: 'MEMBER',
  ),
  Member(
    id: 2,
    groupId: 2,
    userId: 1,
    role: 'MEMBER',
  ),
  Member(
    id: 3,
    groupId: 3,
    userId: 2,
    role: 'MEMBER',
  ),
  Member(
    id: 4,
    groupId: 4,
    userId: 1,
    role: 'MEMBER',
  ),
  Member(
    id: 5,
    groupId: 5,
    userId: 2,
    role: 'MEMBER',
  ),
  Member(
    id: 5,
    groupId: 5,
    userId: 1,
    role: 'MEMBER',
  ),
];

List<Post> posts = [
  Post(
    postId: 1,
    groupId: 1,
    clubMemberId: 1,
    content: '가천대 동문 모임 관리자 김민정님의 정수미 초대 공지를 알려드립니다.',
    type: 'NONE',
    time: DateTime.parse('2024-03-13T11:38:00Z'),
    likes: 5,
    comments: [
      Comment(
        commentId: 1,
        postId: 1,
        author: '김민정',
        content: '환영합니다!',
        createdAt: DateTime.parse('2024-03-13T11:40:00Z'),
      ),
      Comment(
        commentId: 2,
        postId: 1,
        author: '고종범',
        content: '반가워요!',
        createdAt: DateTime.parse('2024-03-13T11:42:00Z'),
      ),
    ],
  ),
  Post(
    postId: 2,
    groupId: 1,
    clubMemberId: 1,
    content: '가천대 동문 모임 첫 번째 모임 일정을 공지합니다.',
    type: 'NONE',
    time: DateTime.parse('2024-03-14T14:10:00Z'),
    likes: 10,
    comments: [
      Comment(
        commentId: 3,
        postId: 2,
        author: '정수미',
        content: '기대돼요!',
        createdAt: DateTime.parse('2024-03-14T14:15:00Z'),
      ),
      Comment(
        commentId: 4,
        postId: 2,
        author: '박재윤',
        content: '참석할게요!',
        createdAt: DateTime.parse('2024-03-14T14:18:00Z'),
      ),
    ],
  ),
  Post(
    postId: 3,
    groupId: 4,
    clubMemberId: 2,
    content: 'INES 그룹 첫 번째 모임을 공지합니다.',
    type: 'NONE',
    time: DateTime.parse('2024-03-15T09:45:00Z'),
    likes: 7,
    comments: [
      Comment(
        commentId: 5,
        postId: 3,
        author: '고종범',
        content: '기대됩니다!',
        createdAt: DateTime.parse('2024-03-15T09:50:00Z'),
      ),
      Comment(
        commentId: 6,
        postId: 3,
        author: '정수미',
        content: '참석하겠습니다!',
        createdAt: DateTime.parse('2024-03-15T09:55:00Z'),
      ),
    ],
  ),
];

List<PostImage> postImages = [
  PostImage(
    postImageId: 1,
    postId: 1,
    path: 'images/flutter_dev.png',
  ),
  PostImage(
    postImageId: 2,
    postId: 2,
    path: 'images/dart_enthusiasts.png',
  ),
];

List<Comment> comments = [
  Comment(
    commentId: 1,
    postId: 1,
    author: '김민정',
    content: '환영합니다!',
    createdAt: DateTime.parse('2024-03-13T11:40:00Z'),
  ),
  Comment(
    commentId: 2,
    postId: 1,
    author: '고종범',
    content: '반가워요!',
    createdAt: DateTime.parse('2024-03-13T11:42:00Z'),
  ),
  Comment(
    commentId: 3,
    postId: 2,
    author: '정수미',
    content: '기대돼요!',
    createdAt: DateTime.parse('2024-03-14T14:15:00Z'),
  ),
  Comment(
    commentId: 4,
    postId: 2,
    author: '박재윤',
    content: '참석할게요!',
    createdAt: DateTime.parse('2024-03-14T14:18:00Z'),
  ),
  Comment(
    commentId: 5,
    postId: 3,
    author: '고종범',
    content: '기대됩니다!',
    createdAt: DateTime.parse('2024-03-15T09:50:00Z'),
  ),
  Comment(
    commentId: 6,
    postId: 3,
    author: '정수미',
    content: '참석하겠습니다!',
    createdAt: DateTime.parse('2024-03-15T09:55:00Z'),
  ),
];
