import 'package:flutter/material.dart';
import 'package:golbang/widgets/sections/comment_item.dart';
import 'package:golbang/widgets/sections/comment_input.dart';

class CommunityPost extends StatefulWidget {
  final Map<String, dynamic> post;

  CommunityPost({required this.post});

  @override
  _CommunityPostState createState() => _CommunityPostState();
}

class _CommunityPostState extends State<CommunityPost> {
  final TextEditingController _commentController = TextEditingController();

  void _toggleLike() {
    setState(() {
      widget.post['likes'] += 1;
    });
  }

  void _addComment() {
    if (_commentController.text.isNotEmpty) {
      setState(() {
        widget.post['comments'].add({
          'author': '현재 사용자',
          'content': _commentController.text,
          'time': '2024년 3월 16일 오후 3시 30분',
        });
        _commentController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('게시물 상세'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(widget.post['profileImage']),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post['author'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.post['time'],
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            if (widget.post['image'] != null)
              Image.asset(widget.post['image']),
            SizedBox(height: 10),
            Text(widget.post['content']),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.thumb_up),
                      onPressed: _toggleLike,
                    ),
                    Text('${widget.post['likes']}'),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.comment),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('댓글 추가'),
                              content: TextField(
                                controller: _commentController,
                                decoration: InputDecoration(hintText: '댓글을 입력하세요'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _addComment();
                                    Navigator.of(context).pop();
                                  },
                                  child: Text('추가'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    Text('${widget.post['comments'].length}'),
                  ],
                ),
              ],
            ),
            Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: widget.post['comments'].length,
                itemBuilder: (context, index) {
                  final comment = widget.post['comments'][index];
                  return CommentItem(comment: comment);
                },
              ),
            ),
            CommentInput(
              controller: _commentController,
              onSubmit: _addComment,
            ),
          ],
        ),
      ),
    );
  }
}
