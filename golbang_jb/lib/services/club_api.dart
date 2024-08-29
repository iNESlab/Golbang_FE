// services/club_api.dart
// 모임 관련 api
// 민: 이 코드는 예시이고, 성문이가 만든 모임 api 코드를 이 파일에다가 넣어주시면 됩니다!

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/club.dart';

class ClubApi {
  final String baseUrl = 'http://127.0.0.1:8000/api/v1';
  final String token;

  ClubApi(this.token);

  // 모임 생성
  Future<Club> createClub({
    required String name,
    required String description,
    String? image,
    required List<int> members,
    required List<int> admins,
  }) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:8000/api/v1/clubs/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'description': description,
        'image': image,
        'members': members,
        'admins': admins,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Club.fromJson(data['data']);
    } else {
      throw Exception('Failed to create club: ${response.body}');
    }
  }


  // 전체 모임 리스트 조회
  Future<List<Club>> getClubs() async {
    final response = await http.get(
      Uri.parse('http://127.0.0.1:8000/api/v1/clubs/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> clubsJson = jsonDecode(response.body);
      return clubsJson.map((json) => Club.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load clubs: ${response.body}');
    }
  }
}