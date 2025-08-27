import 'package:golbang/features/event/data/models/golf_club/responses/golf_club_summary_response_dto.dart';
import 'package:golbang/features/event/domain/entities/golf_club.dart';

import '../models/golf_club/responses/golf_club_detail_response_dto.dart';
import '../models/golf_club/responses/golf_course_detail_response_dto.dart';
import '../models/golf_club/responses/golf_course_summary_response_dto.dart';

extension GolfCourseSummaryMapper on GolfCourseSummaryResponseDto {
  GolfCourseSummary toEntity(){
    return GolfCourseSummary(
        golfCourseId: golfCourseId,
        golfCourseName: golfCourseName,
        holes: holes,
        par: par
    );
  }

}
extension GolfClubSummaryMapper on GolfClubSummaryResponseDto {
  GolfClubSummary toEntity(){
    return GolfClubSummary(
        golfClubId: golfClubId,
        golfClubName: golfClubName,
        address: address,
        longitude: longitude,
        latitude: latitude,
        golfCourseSummaries: golfCourseSummaryResponseDtos.map((d) => d.toEntity()).toList()
    );
  }
}

// ---Detail

extension TeeMapper on TeeResponseDto {
  Tee toEntity() {
    return Tee(
        teeName: teeName,
        holePars: holePars,
        holeHandicaps: holeHandicaps
    );
  }
}

extension GolfCourseDetailMapper on GolfCourseDetailResponseDto {
  GolfCourseDetail toEntity(){
    return GolfCourseDetail(
        golfCourseId: golfCourseId,
        golfCourseName: golfCourseName,
        holes: holes,
        par: par,
        tees: teeDtos.map((d)=>d.toEntity()).toList()
    );
  }

}
extension GolfClubDetailMapper on GolfClubDetailResponseDto {
  GolfClubDetail toEntity(){
    return GolfClubDetail(
        golfClubId: golfClubId,
        golfClubName: golfClubName,
        address: address,
        longitude: longitude,
        latitude: latitude,
        golfCourseDetails: golfCourseDetailResponseDtos.map((d) => d.toEntity()).toList()
    );
  }
}