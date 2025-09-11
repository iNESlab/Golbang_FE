class GolfClubSummary {
  final int golfClubId;
  final String golfClubName;
  final String address;
  final double longitude;
  final double latitude;
  final List<GolfCourseSummary> golfCourseSummaries;


  GolfClubSummary({
    required this.golfClubId,
    required this.golfClubName,
    required this.address,
    required this.longitude,
    required this.latitude,
    required this.golfCourseSummaries
  });

}
class GolfClubDetail {
  final int golfClubId;
  final String golfClubName;
  final String address;
  final double longitude;
  final double latitude;
  final List<GolfCourseDetail> golfCourseDetails;

  GolfClubDetail({
    required this.golfClubId,
    required this.golfClubName,
    required this.address,
    required this.longitude,
    required this.latitude,
    required this.golfCourseDetails
  });

}

class GolfCourseSummary {
  final int golfCourseId;
  final String golfCourseName;
  final int holes;
  final int par;

  GolfCourseSummary({
    required this.golfCourseId,
    required this.golfCourseName,
    required this.holes,
    required this.par,
  });
}

class GolfCourseDetail {
  final int golfCourseId;
  final String golfCourseName;
  final int holes;
  final int par;
  final List<Tee> tees;

  GolfCourseDetail({
    required this.golfCourseId,
    required this.golfCourseName,
    required this.holes,
    required this.par,
    required this.tees,
  });
}

class Tee {
  final String teeName;
  final List<String> holePars;
  final List<String> holeHandicaps;

  Tee({
    // required this.teeId,
    required this.teeName,
    required this.holePars,
    required this.holeHandicaps,
  });
}
