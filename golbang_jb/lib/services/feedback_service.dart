import 'dart:developer';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../global/LoginInterceptor.dart';
import '../repoisitory/secure_storage.dart';

class FeedbackService {
  final SecureStorage storage;
  final dioClient = DioClient();

  FeedbackService(this.storage);

  Future<void> sendFeedback(String message) async {
    try {
      final url = '${dotenv.env['API_HOST']}/api/v1/feedbacks/';

      final response = await dioClient.dio.post(
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
