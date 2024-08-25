
class Post {
  final int postId;
  final int groupId;
  final int clubMemberId;
  final String content;
  final String type;
  final DateTime time;
  final int likes;
  final List<Comment> comments;

  Post({
    required this.postId,
    required this.groupId,
    required this.clubMemberId,
    required this.content,
    required this.type,
    required this.time,
    required this.likes,
    required this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['postId'],
      groupId: json['groupId'],
      clubMemberId: json['clubMemberId'],
      content: json['content'],
      type: json['type'],
      time: DateTime.parse(json['time']),
      likes: json['likes'],
      comments: (json['comments'] as List)
          .map((comment) => Comment.fromJson(comment))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'groupId': groupId,
      'clubMemberId': clubMemberId,
      'content': content,
      'type': type,
      'time': time.toIso8601String(),
      'likes': likes,
      'comments': comments.map((comment) => comment.toJson()).toList(),
    };
  }
}

class Comment {
  final int commentId;
  final int postId;
  final String author;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.commentId,
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['commentId'],
      postId: json['postId'],
      author: json['author'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'postId': postId,
      'author': author,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class PostImage {
  final int postImageId;
  final int postId;
  final String path;

  PostImage({
    required this.postImageId,
    required this.postId,
    required this.path,
  });

  factory PostImage.fromJson(Map<String, dynamic> json) {
    return PostImage(
      postImageId: json['postImageId'],
      postId: json['postId'],
      path: json['path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postImageId': postImageId,
      'postId': postId,
      'path': path,
    };
  }
}
