
class GolfClub {
  final String clubName;
  final String address;
  final List<GolfCourse> courses;

  GolfClub({
    required this.clubName,
    required this.address,
    required this.courses,
  });

  factory GolfClub.fromJson(Map<String, dynamic> json) {
    return GolfClub(
      clubName: json['club_name'],
      address: json['address'],
      courses: (json['courses'] as List)
          .map((course) => GolfCourse.fromJson(course))
          .toList(),
    );
  }
}

class GolfCourse {
  final String courseName;
  final int holes;
  final int par;
  final List<int> holePars;
  final List<int> holeHandicaps;

  GolfCourse({
    required this.courseName,
    required this.holes,
    required this.par,
    required this.holePars,
    required this.holeHandicaps,
  });

  factory GolfCourse.fromJson(Map<String, dynamic> json) {
    return GolfCourse(
      courseName: json['course_name'],
      holes: json['holes'],
      par: json['par'],
      holePars: List<int>.from(json['hole_pars']),
      holeHandicaps: List<int>.from(json['hole_handicaps']),
    );
  }
}