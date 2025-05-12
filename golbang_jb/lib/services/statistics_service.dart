import 'dart:developer';
import 'dart:async';
import 'package:golbang/global/PrivateClient.dart';
import '../repoisitory/secure_storage.dart';
import '../models/get_statistics_overall.dart';
import '../models/get_statistics_yearly.dart';
import '../models/get_statistics_ranks.dart';
import '../models/get_statistics_period.dart';

class StatisticsService {
  final SecureStorage storage;
  final privateClient = PrivateClient();

  StatisticsService(this.storage);

  // API 테스트 성공
  Future<ClubStatistics?> fetchClubStatistics(int clubId) async {
    try {
      // TODO: endpoint 뒤에 슬레시 필요한지 아닌지 통일
      var uri = "/api/v1/clubs/statistics/ranks/?club_id=$clubId/";

      var response = await privateClient.dio.get(uri);
      if (response.statusCode == 200) {
        final jsonData = response.data['data'];
        // log(jsonData);
        if (jsonData != null) {
          return ClubStatistics.fromJson(jsonData);
        }
      }
    } catch (e) {
      log('Failed to load club statistics: $e');
    }
    return null;
  }

  // API 테스트 성공
  Future<OverallStatistics?> fetchOverallStatistics() async {
    try {
      // TODO: endpoint 뒤에 슬레시 필요한지 아닌지 통일
      var uri = "/api/v1/participants/statistics/overall/";

      var response = await privateClient.dio.get(uri);
      if (response.statusCode == 200) {
        final jsonData = response.data['data'];
        if (jsonData != null) {
          return OverallStatistics.fromJson(jsonData);
        }
      } else if (response.statusCode == 404) {
        throw Exception('No event data available for this date.');
      } else {
        throw Exception('Failed to load overall statistics');
      }
    } catch (e) {
      log('Failed to load overall statistics: $e');
    }
    return null;
  }

  // Future<OverallStatistics> fetchOverallStatistics() async {
  //   try {
  //     final accessToken = await storage.readAccessToken();
  //     var uri = Uri.parse("${dotenv.env['API_HOST']}/api/v1/participants/statistics/overall/");
  //
  //     Map<String, String> headers = {
  //       "Content-type": "application/json",
  //       "Authorization": "Bearer $accessToken"
  //     };
  //
  //     var response = await http.get(uri, headers: headers);
  //
  //     if (response.statusCode == 200) {
  //       final jsonData = json.decode(utf8.decode(response.bodyBytes))['data'];
  //       if (jsonData != null) {
  //         return OverallStatistics.fromJson(jsonData);
  //       }
  //     }
  //   } catch (e) {
  //     log('Error fetching overall statistics: $e');
  //   }
  //
  //   // 기본값 반환
  //   return OverallStatistics(
  //     averageScore: 0.0,
  //     bestScore: 0,
  //     handicapBestScore: 0,
  //     gamesPlayed: 0,
  //   );
  // }

  // API 테스트 성공
  Future<YearStatistics?> fetchYearStatistics(String year) async {
    try {
      // TODO: endpoint 뒤에 슬레시 필요한지 아닌지 통일
      var uri = "/api/v1/participants/statistics/yearly/$year/";

      var response = await privateClient.dio.get(uri);

      if (response.statusCode == 200) {
        final jsonData = response.data['data'];
        if (jsonData != null) {
          return YearStatistics.fromJson(jsonData);
        }
      } else if (response.statusCode == 404) {
        throw Exception("404");
      } else {
        throw Exception('Failed to load yearly statistics');
      }
    } catch (e) {
      log('Failed to load year statistics for $year: $e');
    }
    return null;
  }

  // API 테스트 완료 - 통계 페이지에서 에러 발생하여 수정함
  Future<PeriodStatistics?> fetchPeriodStatistics(String startDate, String endDate) async {
    try {
      var uri =
          "/api/v1/participants/statistics/period/?start_date=$startDate&end_date=$endDate";

      var response = await privateClient.dio.get(uri);
      if (response.statusCode == 200) {
        final jsonData = response.data['data'];
        if (jsonData != null) {
          return PeriodStatistics.fromJson(jsonData);
        }
      } else if (response.statusCode == 404) {
        throw Exception("404");
      } else {
        throw Exception('Failed to load yearly statistics');
      }
    } catch (e) {
      log('Failed to load period statistics: $e');
    }
    return null;
  }
}
