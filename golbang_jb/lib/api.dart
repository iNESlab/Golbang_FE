import 'models/group.dart';
import 'models/member.dart';
import 'models/post.dart';
import 'models/user.dart';
import 'global_config.dart';

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


User? getUserByToken(List<User> users, String token) {
  // List에서 특정 token과 일치하는 User를 찾아 반환
  for (var user in users) {
    if (user.userToken == token) {
      return user;
    }
  }
  // 일치하는 User가 없으면 null 반환
  return null;
}