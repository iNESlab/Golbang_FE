import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/feedback_service.dart';
import '../../repoisitory/secure_storage.dart';

class FeedbackPage extends ConsumerStatefulWidget {
  const FeedbackPage({super.key});

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  late FeedbackService _feedbackService;

  @override
  void initState() {
    super.initState();
    _feedbackController.addListener(_onTextChanged);
    final secureStorage = ref.read(secureStorageProvider);
    _feedbackService = FeedbackService(secureStorage);
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isButtonEnabled = _feedbackController.text.isNotEmpty;
    });
  }

  Future<void> _sendFeedback() async {
    final message = _feedbackController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      await _feedbackService.sendFeedback(message);
      _feedbackController.clear();
      _showAlertDialog(
        title: "피드백이 보내졌습니다.",
        content: "소중한 피드백을 주셔서 감사합니다.",
        isSuccess: true,
      );
    } catch (e) {
      _showAlertDialog(
        title: "전송에 실패했어요.",
        content: "다시 시도해주세요.",
        isSuccess: false,
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isButtonEnabled = false;
      });
    }
  }

  void _showAlertDialog({
    required String title,
    required String content,
    required bool isSuccess,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isSuccess ? Colors.green : Colors.red,
            ),
          ),
          content: Text(content, style: const TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () {
                if (isSuccess) context.go('/home'); // Exit page if successful
                context.pop(); // Close dialog
              },
              child: const Text(
                "확인",
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '피드백 보내기',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '시간은 가장 귀중한 자원입니다. 시간을 효율적으로 사용할 수 있도록 도와드릴게요.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _feedbackController,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: 'Golbang을 어떻게 개선하면 좋을까요?',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isButtonEnabled && !_isLoading ? _sendFeedback : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isButtonEnabled
                      ? Colors.green
                      : Colors.grey[300],
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  '피드백 보내기',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
