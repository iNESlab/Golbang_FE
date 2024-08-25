import 'models/group.dart';
import 'models/member.dart';
import 'models/post.dart';
import 'models/user.dart';
import 'global_config.dart';

List<Group> getUserGroups(String accessToken) {
  return GlobalConfig.groups;
}
Future<Map<String, dynamic>> getUserGroupsFromApi(String accessToken) async {
  int userId;
  if (accessToken == 'token_john_doe') {
    userId = 1;
  } else if (accessToken == 'token_jane_doe') {
    userId = 2;
  } else {
    return {
      "status": 401,
      "message": "Invalid token",
      "data": []
    };
  }

  List<Member> userMembers = members.where((member) => member.userId == userId).toList();
  List<Group> userGroups = userMembers.map((member) {
    Group group = GlobalConfig.groups.firstWhere((g) => g.id == member.groupId);
    return group;
  }).toList();

  return {
    "status": 200,
    "message": "Success",
    "data": userGroups.map((group) => group.toJson()).toList(),
  };
}

void addGroup(String groupName, String imagePath) {
  GlobalConfig.groups.add(
    Group(
      id: GlobalConfig.groups.length + 1,
      name: groupName,
      description: '새로운 그룹 설명',
      image: imagePath,
      membersCount: 1,
      createdAt: DateTime.now(),
      isActive: true,
    ),
  );
}

Map<String, dynamic> getGroupPosts(int groupId) {
  var groupPosts = posts.where((post) => post.groupId == groupId).map((post) {
    return {
      "post_id": post.postId,
      "author": users.firstWhere((user) => user.userId == post.clubMemberId).fullname,
      "profileImage": users.firstWhere((user) => user.userId == post.clubMemberId).profileImage,
      "time": post.time.toIso8601String(),
      "content": post.content,
      "image": postImages.firstWhere((image) => image.postId == post.postId, orElse: () => PostImage(postImageId: 0, postId: post.postId, path: '')).path,
      "likes": post.likes,
      "comments": post.comments.map((comment) => {
        "author": comment.author,
        "content": comment.content,
        "time": comment.createdAt.toIso8601String(),
      }).toList(),
    };
  }).toList();

  return {
    "status": 200,
    "message": "Success",
    "data": groupPosts,
  };
}

Map<String, dynamic> getGroupMembers(int groupId) {
  var groupMembers = members.where((member) => member.groupId == groupId).map((member) {
    var user = users.firstWhere((user) => user.userId == member.userId);
    return {
      "user_id": user.userId,
      "username": user.username,
      "fullname": user.fullname,
      "email": user.email,
      "profileImage": user.profileImage,
    };
  }).toList();

  return {
    "status": 200,
    "message": "Success",
    "data": groupMembers,
  };
}