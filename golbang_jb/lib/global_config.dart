import 'models/bookmark.dart';
import 'models/event.dart';
import 'models/group.dart';
import 'models/member.dart';
import 'models/post.dart';
import 'models/user.dart';

// 민정 사용 로직:
import 'models/users.dart';
import 'models/club.dart';
import 'models/club_member.dart';
import 'models/events.dart';
import 'models/participant.dart';

const String testEmail = 'test@email.com';
const String testPassword = '1q2w3e4r';
const String testOTP = '1234';

class GlobalConfig {
  static List<Bookmark> bookmarks = [
    Bookmark('내 프로필', '-15.9', 'G핸디'),
    Bookmark('스코어', '72(-1)', 'Par-Tee Time', '23.02.12'),
    Bookmark('기록', '100', '99등', '23.02.07'),
  ];

  // 데이터가 아직 준비되지 않았을 때를 위한 더미 데이터
  static List<Event> events = [
    Event(
      eventId: 8,
      eventTitle: "Annual Golf Tournament",
      location: "Sunset Golf Club",
      startDateTime: DateTime.parse("2024-08-02T18:00:00+09:00"),
      endDateTime: DateTime.parse("2024-08-03T02:00:00+09:00"),
      repeatType: "NONE",
      gameMode: "MP",
      alertDateTime: null,
      participantsCount: 2,
      partyCount: 0,
      acceptCount: 0,
      denyCount: 0,
      pendingCount: 2,
      participants: [
        Participant(
          statusType: "ACCEPT",
          teamType: "A",
          groupType: 1,
          sumScore: 72,
          rank: "1",
          handicapScore: 70,
          handicapRank: "1",
          points: 2
        ),
        Participant(
          statusType: "PENDING",
          teamType: "B",
          groupType: 2,
          sumScore: 75,
          rank: "2",
          handicapScore: 71,
          handicapRank: "2",
          points: 1
        ),
      ], group: '가천대 동문',
    ),
  ];


  // List<Club> club = [
  //   Club(
  //     id: 1,
  //     name: '가천대 동문',
  //     description: '가천대 동문 그룹 모임',
  //     image: 'assets/images/dragon.jpeg',
  //     createdAt: DateTime.parse('2024-07-01T00:00:00Z'),
  //     members: [
  //       ClubMember(
  //           user: Users(
  //             userId: 'ming',
  //             email: 'ming@email.com',
  //             name: 'Test Ming',
  //             handicap: 1,
  //             studentId: '1',
  //             phoneNumber: '123-4567-8900',
  //             address: '123',
  //
  //         ),
  //         role: 'ADMIN',
  //         totalPoints: 100,
  //         totalRank: '1',
  //         totalHandicapRank: '2',
  //         totalAvgScore: 89,
  //         totalHandicapAvgScore: 84
  //       )
  //       ]
  //   )
  // ];
  //
  // List<ClubMember> clubMember = [
  //   ClubMember(
  //     user: Users(
  //       userId: 1,
  //       userToken: 'token_john_doe',
  //       username: 'john_doe',
  //       role: 'ROLE_USER',
  //       fullname: 'John Doe',
  //       email: 'john.doe@example.com',
  //       loginType: 'normal',
  //       provider: 'local',
  //       password: 'password123',
  //       mobile: '123-456-7890',
  //       address: '123 Main St, Anytown, USA',
  //       dateOfBirth: DateTime(1990, 1, 1),
  //       handicap: 'None',
  //       studentId: 'S12345678',
  //       profileImage: 'assets/images/apple.png',
  //       createdAt: DateTime.now(),
  //       updatedAt: DateTime.now(),
  //       recentConnectionTime: DateTime.now(),
  //       releaseAt: DateTime.now().add(Duration(days: 365)),
  //     ),
  //     role: 'ADMIN',
  //     totalPoints: 100,
  //     totalRank: '1',
  //     totalHandicapRank: '2',
  //     totalAvgScore: 89,
  //     totalHandicapAvgScore: 84
  //   ),
  // ];

  static List<Group> groups = [
    Group(
      id: 1,
      name: '가천대 동문',
      description: '가천대 동문 그룹 모임',
      image: 'assets/images/dragon.jpeg',
      membersCount: 7,
      createdAt: DateTime.parse('2024-07-01T00:00:00Z'),
      isActive: true,
    ),
    Group(
      id: 2,
      name: 'INES',
      description: 'INES 그룹',
      image: 'assets/images/facebook.png',
      membersCount: 7,
      createdAt: DateTime.parse('2024-06-01T00:00:00Z'),
      isActive: true,
    ),
    Group(
      id: 3,
      name: '성남 북부신',
      description: '성남 북부신 그룹',
      image: 'assets/images/kakao.png',
      membersCount: 7,
      createdAt: DateTime.parse('2024-06-15T00:00:00Z'),
      isActive: true,
    ),
    Group(
      id: 4,
      name: '골프에 미치다',
      description: '골프에 미치다 그룹',
      image: 'assets/images/naver.png',
      membersCount: 7,
      createdAt: DateTime.parse('2024-06-20T00:00:00Z'),
      isActive: true,
    ),
    Group(
      id: 5,
      name: '파티타임',
      description: '파티타임 그룹',
      image: 'assets/images/google.png',
      membersCount: 7,
      createdAt: DateTime.parse('2024-06-25T00:00:00Z'),
      isActive: true,
    ),
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
