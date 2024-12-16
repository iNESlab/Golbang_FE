import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../repoisitory/secure_storage.dart';

class FeedbackService {
  final SecureStorage storage;

  FeedbackService(this.storage);

  Future<Map<String, dynamic>> sendFeedback(String message) async {
    try {
      final url = Uri.parse('${dotenv.env['API_HOST']}/api/v1/feedbacks/');
      final accessToken = await storage.readAccessToken();

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 201) {
        print("Feedback created successfully");
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        throw Exception('Failed to send feedback: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error occurred while creating feedback: $e');
      throw Exception('Unexpected error: $e');
    }
  }
}
