import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

/// 브라우저 안 띄우고 OS 다운로드로 받기
Future<void> enqueueDownload(Uri downloadUri, BuildContext context) async {
  final savedDir = await _downloadsDir();
  final fileName = _inferFileName(downloadUri) ?? 'download.xlsx';

  if (!await savedDir.exists()) {
    await savedDir.create(recursive: true);
  }

  await FlutterDownloader.enqueue(
    url: downloadUri.toString(),
    savedDir: savedDir.path,
    fileName: fileName,
    showNotification: true,          // 상태바 알림
    openFileFromNotification: true,  // 알림에서 열기
    saveInPublicStorage: Platform.isAndroid, // 안드로이드: 공개 Downloads
  );

  // 유틸 파일에서는 context.mounted로 체크
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('다운로드 시작: $fileName')),
  );
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('알림을 확인해주세요')),
  );
}

// ----- 아래는 유틸 내부 전용 헬퍼들(프라이빗) -----

Future<Directory> _downloadsDir() async {
  if (Platform.isAndroid) {
    final pub = Directory('/storage/emulated/0/Download');
    return await pub.exists() ? pub : (await getExternalStorageDirectory())!;
  } else {
    return await getApplicationDocumentsDirectory();
  }
}

String? _inferFileName(Uri u) {
  // /calculator/download?path=<파일명> 이면 파라미터 우선
  final p = u.queryParameters['path'];
  if (p != null && p.isNotEmpty) return p.split('/').last;

  // 아니면 URL 마지막 세그먼트
  if (u.pathSegments.isNotEmpty) return u.pathSegments.last;

  return null;
}
