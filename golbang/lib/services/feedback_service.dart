import 'dart:developer';
import 'dart:convert';
import '../core/network/PrivateClient.dart';
import '../repoisitory/secure_storage.dart';

class FeedbackService {
  final SecureStorage storage;
  final privateClient = PrivateClient();

  FeedbackService(this.storage);

  // API Test 완료
  Future<void> sendFeedback(String message) async {
    try {
      const url = '/api/v1/feedbacks/';

      final response = await privateClient.dio.post(
        url,
        data: jsonEncode({'message': message}),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to send feedback: ${response.statusCode} ${response.data}');
      }
    } catch (e) {
      log('Error occurred while creating feedback: $e');
      throw Exception('Unexpected error: $e');
    }
  }
}
