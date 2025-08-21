import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class PostWritePage extends StatefulWidget {
  final int clubId;

  const PostWritePage({super.key, required this.clubId});

  @override
  State<PostWritePage> createState() => _PostWriteState();
}

class _PostWriteState extends State<PostWritePage> {
  final TextEditingController _controller = TextEditingController();
  File? _image;
  bool _isLoading = false;
  // 예시: 기존 글쓰기 UI에 "이벤트 선택"만 추가하는 부분

  final List<Map<String, String>> events = [
    {'title': '7월 정기 모임', 'location': '홍대 스터디룸 A'},
    {'title': '워크숍', 'location': '강남 위워크'},
    {'title': '온라인 세션', 'location': 'Zoom'},
  ];
  Map<String, String>? selectedEvent;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // TODO: 서버 업로드 로직 구현
      await Future.delayed(const Duration(seconds: 2)); // 예시용 대기

      // 예: 서버에 post 요청 보내고 이미지 포함

      if (mounted)context.pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 실패: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('글쓰기'),
        centerTitle: false,
        titleSpacing: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: const Text(
              '완료',
              style: TextStyle(
                color: Colors.green,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_image != null) ...[
              Stack(
                children: [
                  Image.file(_image!),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: () => setState(() => _image = null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // 🔽 여기만 추가됨
            DropdownButtonFormField<Map<String, String>>(
              value: selectedEvent,
              hint: const Text('이벤트를 선택하세요'),
              isExpanded: true,
              items: events.map((event) {
                return DropdownMenuItem(
                  value: event,
                  child: Text('${event['title']} • ${event['location']}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedEvent = value;
                });
              },
              decoration: const InputDecoration(
                labelText: '이벤트',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _controller,
              maxLines: null,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: '내용을 입력하세요',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 10),
            // ElevatedButton.icon(
            //   onPressed: _pickImage,
            //   icon: const Icon(Icons.image),
            //   label: const Text('이미지 선택'),
            // ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
