import 'dart:io';

import 'package:excel/excel.dart' as xx;
import 'package:path_provider/path_provider.dart';  // path_provider 패키지 임포트


Future<String?> createScoreExcelFile({
  required int eventId,
  required List<dynamic> participants,
  Map<String, dynamic>? teamAScores,
  Map<String, dynamic>? teamBScores,
}) async {
  // 엑셀 파일 생성
  var excel = xx.Excel.createExcel();
  var sheet = excel['Sheet1'];

  // 열 제목 설정 (기본은 행 형태로)
  List<String> columnTitles = [
    '팀',
    '참가자',
    '전반전',
    '후반전',
    '전체 스코어',
    '핸디캡 스코어',
    'hole 1',
    'hole 2',
    'hole 3',
    'hole 4',
    'hole 5',
    'hole 6',
    'hole 7',
    'hole 8',
    'hole 9',
    'hole 10',
    'hole 11',
    'hole 12',
    'hole 13',
    'hole 14',
    'hole 15',
    'hole 16',
    'hole 17',
    'hole 18'
  ];

  // 팀 데이터와 참가자별 점수를 병합하여 정렬
  List<Map<String, dynamic>> sortedParticipants = [
    if (teamAScores != null)
      {
        'team': 'Team A',
        'participant_name': '-',
        'front_nine_score': teamAScores['front_nine_score'],
        'back_nine_score': teamAScores['back_nine_score'],
        'total_score': teamAScores['total_score'],
        'handicap_score': '-',
        'scorecard': List.filled(18, '-'),
      },
    if (teamBScores != null)
      {
        'team': 'Team B',
        'participant_name': '-',
        'front_nine_score': teamBScores['front_nine_score'],
        'back_nine_score': teamBScores['back_nine_score'],
        'total_score': teamBScores['total_score'],
        'handicap_score': '-',
        'scorecard': List.filled(18, '-'),
      },
    ...participants.map((participant) =>
    {
      'team': participant['team'], // 팀 정보 추가
      'participant_name': participant['participant_name'],
      'front_nine_score': participant['front_nine_score'],
      'back_nine_score': participant['back_nine_score'],
      'total_score': participant['total_score'],
      'handicap_score': participant['handicap_score'],
      'scorecard': participant['scorecard'],
    }),
  ];

  // 팀 기준으로 정렬
  sortedParticipants.sort((a, b) => a['team'].compareTo(b['team']));

  // 데이터를 행 기준으로 변환
  List<List<dynamic>> rows = [
    columnTitles, // 제목
    ...sortedParticipants.map((participant) {
      return [
        participant['team'],
        participant['participant_name'],
        participant['front_nine_score'],
        participant['back_nine_score'],
        participant['total_score'],
        participant['handicap_score'],
        ...List.generate(18, (i) =>
        participant['scorecard'].length > i
            ? participant['scorecard'][i]
            : '-'),
      ];
    }),
  ];

  // Transpose 적용 (행과 열 교환)
  List<List<dynamic>> transposedData = List.generate(
    rows[0].length,
        (colIndex) => rows.map((row) => row[colIndex]).toList(),
  );

  // 엑셀에 데이터 쓰기
  for (var row in transposedData) {
    sheet.appendRow(row);
  }

  // 외부 저장소 경로 가져오기
  Directory? directory;

  if (Platform.isAndroid) {
    // Android: 외부 저장소 경로 가져오기
    directory = await getExternalStorageDirectory();
  } else if (Platform.isIOS) {
    // iOS: 문서 디렉토리 가져오기
    directory = await getApplicationDocumentsDirectory();
  }

  if (directory != null) {
    String filePath = '${directory.path}/event_scores_$eventId.xlsx';
    File file = File(filePath);

    // 파일 쓰기
    await file.writeAsBytes(excel.encode()!);
    return filePath;
  }
  return null;
}