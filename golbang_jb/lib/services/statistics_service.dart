import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../repoisitory/secure_storage.dart';
import '../models/get_statistics_overall.dart';
import '../models/get_statistics_yearly.dart';
import '../models/get_statistics_ranks.dart';
import '../models/get_statistics_period.dart';

class StatisticsService {
  final SecureStorage storage;

  StatisticsService(this.storage);

  Future<ClubStatistics?> fetchClubStatistics(int clubId) async {
    try {
      final accessToken = await storage.readAccessToken();
      // TODO: endpoint 뒤에 슬레시 필요한지 아닌지 통일
      var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/clubs/statistics/ranks/?club_id=$clubId");

      Map<String, String> headers = {
        "Content-type": "application/json",
        "Authorization": "Bearer $accessToken"
      };

      var response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes))['data'];
        print(jsonData);
        if (jsonData != null) {
          return ClubStatistics.fromJson(jsonData);
        }
      }
    } catch (e) {
      print('Failed to load club statistics: $e');
    }
    return null;
  }

  Future<OverallStatistics?> fetchOverallStatistics() async {
    try {
      final accessToken = await storage.readAccessToken();
      // TODO: endpoint 뒤에 슬레시 필요한지 아닌지 통일
      var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/participants/statistics/overall/");

      Map<String, String> headers = {
        "Content-type": "application/json",
        "Authorization": "Bearer $accessToken"
      };

      var response = await http.get(uri, headers: headers);
      print("hello");
      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes))['data'];
        print("overall");
        print(jsonData);
        print("overall");
        if (jsonData != null) {
          return OverallStatistics.fromJson(jsonData);
        }
      }
    } catch (e) {
      print('Failed to load overall statistics: $e');
    }
    return null;
  }

  Future<YearStatistics?> fetchYearStatistics(String year) async {
    try {
      final accessToken = await storage.readAccessToken();
      // TODO: endpoint 뒤에 슬레시 필요한지 아닌지 통일
      var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/participants/statistics/yearly/$year/");

      Map<String, String> headers = {
        "Content-type": "application/json",
        "Authorization": "Bearer $accessToken"
      };

      var response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes))['data'];
        if (jsonData != null) {
          return YearStatistics.fromJson(jsonData);
        }
      }
    } catch (e) {
      print('Failed to load year statistics for $year: $e');
    }
    return null;
  }

  Future<PeriodStatistics?> fetchPeriodStatistics(String startDate, String endDate) async {
    try {
      final accessToken = await storage.readAccessToken();
      var uri = Uri.parse(
          "${dotenv.env['API_HOST']}/api/v1/participants/statistics/period/?start_date=$startDate&end_date=$endDate");

      Map<String, String> headers = {
        "Content-type": "application/json",
        "Authorization": "Bearer $accessToken"
      };

      var response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes))['data'];
        if (jsonData != null) {
          return PeriodStatistics.fromJson(jsonData);
        }
      }
    } catch (e) {
      print('Failed to load period statistics: $e');
    }
    return null;
  }
}
