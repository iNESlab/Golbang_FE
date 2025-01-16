/* pages/models/get_event_result_participants_ranks.dart
* 이벤트 결과 조회 시 사용자 정보 (이름, 이미지, 스코어, 랭킹)
**/
class GetEventResultParticipantsRanks {
  final String userId;
  final String name;
  final String? profileImage;
  final int sumScore;
  final int handicapScore;
  final String rank;
  final String handicapRank;
  final List<int> scorecard;

  GetEventResultParticipantsRanks({
    required this.userId,
    required this.name,
    String? profileImage,
    required this.sumScore,
    required this.handicapScore,
    required this.rank,
    required this.handicapRank,
    required this.scorecard,
  }) : profileImage = (profileImage == null || profileImage.isEmpty) ? null : profileImage;

  factory GetEventResultParticipantsRanks.fromJson(Map<String, dynamic> json) {
    return GetEventResultParticipantsRanks(
      userId: json['user_id'],
      name: json['name'],
      profileImage: json['profile_image'],
      sumScore: json['sum_score'],
      handicapScore: json['handicap_score'],
      rank: json['rank'],
      handicapRank: json['handicap_rank'],
      scorecard: List<int>.from(json['scorecard']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'profile_image': profileImage,
      'sum_score': sumScore,
      'handicap_score': handicapScore,
      'rank': rank,
      'handicap_rank': handicapRank,
      'scorecard': scorecard,
    };
  }
}