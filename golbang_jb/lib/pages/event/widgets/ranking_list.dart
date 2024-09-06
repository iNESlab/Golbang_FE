/*
pages/event/widgets/ranking_list.dart
이벤트에 참여한 사람들의 랭킹 정보를 표시
*/
import 'package:flutter/material.dart';

class RankingList extends StatelessWidget {
  final List<Map<String, String>> participants;

  const RankingList({required this.participants});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: participants.map((participant) {
        return ListTile(
          leading: Text(participant['rank']!),
          title: Text(participant['name']!),
          trailing: Text(participant['stroke']!),
        );
      }).toList(),
    );
  }
}
