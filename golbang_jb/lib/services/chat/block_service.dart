import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../global/PrivateClient.dart';

/// 사용자 차단 및 신고 서비스
/// 사용자 차단, 신고, 차단 목록 관리 등의 기능을 제공합니다.
class BlockService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final PrivateClient _privateClient = PrivateClient();

  Set<String> _blockedUsers = {};
  Set<String> _showBlockedMessages = {}; // 차단된 메시지 중 보여줄 메시지 ID들

  /// 차단된 사용자 목록 getter
  Set<String> get blockedUsers => _blockedUsers;

  /// 표시할 차단된 메시지 목록 getter
  Set<String> get showBlockedMessages => _showBlockedMessages;

  /// 차단된 사용자 목록 초기화
  Future<void> loadBlockedUsers() async {
    await _syncBlockedUsersFromServer();
  }

  /// 서버에서 차단된 사용자 목록 동기화
  Future<void> _syncBlockedUsersFromServer() async {
    try {
      log('🔄 BlockService: 서버에서 차단된 사용자 목록 동기화 시작...');

      final response = await _privateClient.get('/api/v1/chat/blocked-users/');

      if (response.statusCode == 200) {
        final data = response.data;
        final blockedUsersData = data['blocked_users'] as List;

        // 서버에서 가져온 차단된 사용자 ID 목록
        final serverBlockedUsers = blockedUsersData
            .map((user) => user['user_id'].toString())
            .toSet();

        log('🔄 BlockService: 서버에서 가져온 차단된 사용자: $serverBlockedUsers');

        // 로컬 저장소에 저장
        await _storage.write(key: 'blocked_users', value: jsonEncode(serverBlockedUsers.toList()));

        _blockedUsers = serverBlockedUsers;

        log('✅ BlockService: 서버와 로컬 차단 목록 동기화 완료');
      } else {
        log('⚠️ BlockService: 서버 동기화 실패, 로컬 저장소에서 로드');
        await _loadBlockedUsersFromLocal();
      }
    } catch (e) {
      log('❌ BlockService: 서버 동기화 실패: $e, 로컬 저장소에서 로드');
      await _loadBlockedUsersFromLocal();
    }
  }

  /// 로컬 저장소에서 차단된 사용자 목록 로드
  Future<void> _loadBlockedUsersFromLocal() async {
    try {
      final blockedUsers = await _storage.read(key: 'blocked_users') ?? '[]';
      final List<dynamic> blockedList = jsonDecode(blockedUsers);

      _blockedUsers = Set<String>.from(blockedList);

      log('🔧 BlockService: 로컬에서 차단된 사용자 목록 로드: $_blockedUsers');
    } catch (e) {
      log('❌ BlockService: 로컬 차단된 사용자 목록 로드 실패: $e');
      _blockedUsers = {};
    }
  }

  /// 사용자 차단
  Future<bool> blockUser({
    required String blockedUserId,
    required String reason,
  }) async {
    try {
      // 이미 차단된 사용자인지 확인
      if (_blockedUsers.contains(blockedUserId)) {
        log('⚠️ BlockService: 이미 차단된 사용자: $blockedUserId');
        return false;
      }

      log('🔧 BlockService: 사용자 차단 시작: $blockedUserId');

      // 백엔드 API로 사용자 차단
      final response = await _privateClient.post(
        '/api/v1/chat/block-user/',
        data: {
          'blocked_user_id': blockedUserId,
          'reason': reason,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 차단된 사용자 ID를 로컬에 저장
        final blockedUsers = await _storage.read(key: 'blocked_users') ?? '[]';
        final List<dynamic> blockedList = jsonDecode(blockedUsers);

        if (!blockedList.contains(blockedUserId)) {
          blockedList.add(blockedUserId);
          await _storage.write(key: 'blocked_users', value: jsonEncode(blockedList));
        }

        // 메모리 상태 업데이트
        _blockedUsers.add(blockedUserId);

        log('✅ BlockService: 사용자 차단 성공: $blockedUserId');
        return true;
      } else if (response.statusCode == 500 &&
                 response.data != null &&
                 response.data.toString().contains('Duplicate entry')) {
        // 이미 차단된 사용자 에러 처리
        log('⚠️ BlockService: 이미 차단된 사용자 (서버): $blockedUserId');

        // 로컬 상태도 업데이트 (서버와 동기화)
        _blockedUsers.add(blockedUserId);
        final blockedUsers = await _storage.read(key: 'blocked_users') ?? '[]';
        final List<dynamic> blockedList = jsonDecode(blockedUsers);
        if (!blockedList.contains(blockedUserId)) {
          blockedList.add(blockedUserId);
          await _storage.write(key: 'blocked_users', value: jsonEncode(blockedList));
        }

        return false;
      } else {
        throw Exception('차단 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ BlockService: 사용자 차단 실패: $e');
      return false;
    }
  }

  /// 사용자 차단 해제
  Future<bool> unblockUser(String blockedUserId) async {
    try {
      log('🔓 BlockService: 차단 해제 시작: $blockedUserId');

      // 백엔드 API로 사용자 차단 해제
      final response = await _privateClient.post(
        '/api/v1/chat/unblock-user/',
        data: {
          'blocked_user_id': blockedUserId,
        },
      );

      if (response.statusCode == 200) {
        // 로컬 저장소에서 차단된 사용자 제거
        final blockedUsers = await _storage.read(key: 'blocked_users') ?? '[]';
        final List<dynamic> blockedList = jsonDecode(blockedUsers);
        blockedList.remove(blockedUserId);
        await _storage.write(key: 'blocked_users', value: jsonEncode(blockedList));

        // 메모리 상태 업데이트
        _blockedUsers.remove(blockedUserId);

        log('✅ BlockService: 사용자 차단 해제 성공: $blockedUserId');
        return true;
      } else {
        throw Exception('차단 해제 요청 실패');
      }
    } catch (e) {
      log('❌ BlockService: 사용자 차단 해제 실패: $e');
      return false;
    }
  }

  /// 모든 차단 해제 (개발/테스트용)
  Future<bool> clearAllBlockedUsers() async {
    try {
      log('🗑️ BlockService: 서버의 모든 차단 해제 시작...');

      // 서버에서 모든 차단 해제
      final response = await _privateClient.delete('/api/v1/chat/clear-blocked-users/');

      if (response.statusCode == 200) {
        log('✅ BlockService: 서버에서 모든 차단 해제 완료: ${response.data['message']}');

        // 로컬 저장소도 초기화
        await _storage.delete(key: 'blocked_users');
        log('🗑️ BlockService: 로컬 저장소도 초기화 완료');

        _blockedUsers.clear();
        _showBlockedMessages.clear();

        return true;
      } else {
        throw Exception('서버에서 차단 해제 실패');
      }
    } catch (e) {
      log('❌ BlockService: 전체 차단 해제 실패: $e');
      return false;
    }
  }

  /// 신고 제출
  Future<bool> submitReport({
    required String messageId,
    required String reason,
    required String detail,
  }) async {
    try {
      // 신고 유형 매핑
      String reportType = 'OTHER';
      switch (reason) {
        case '스팸 또는 광고':
          reportType = 'SPAM';
          break;
        case '욕설 또는 비하':
          reportType = 'ABUSE';
          break;
        case '부적절한 내용':
          reportType = 'INAPPROPRIATE';
          break;
        case '개인정보 유출':
          reportType = 'PRIVACY';
          break;
        case '기타':
          reportType = 'OTHER';
          break;
      }

      // 백엔드 API로 신고 제출
      final response = await _privateClient.post(
        '/api/v1/chat/report-message/',
        data: {
          'message_id': messageId,
          'report_type': reportType,
          'reason': reason,
          'detail': detail,
        },
      );

      if (response.statusCode == 201) {
        log('✅ BlockService: 신고 접수 성공: $messageId');
        return true;
      } else {
        throw Exception('신고 제출 실패');
      }
    } catch (e) {
      log('❌ BlockService: 신고 제출 실패: $e');
      return false;
    }
  }

  /// 차단된 메시지 토글 (보이기/숨기기)
  void toggleBlockedMessage(String messageId) {
    if (_showBlockedMessages.contains(messageId)) {
      _showBlockedMessages.remove(messageId);
    } else {
      _showBlockedMessages.add(messageId);
    }
    log('🔄 BlockService: 차단된 메시지 토글: $messageId, 표시: ${_showBlockedMessages.contains(messageId)}');
  }

  /// 사용자 차단 여부 확인
  bool isUserBlocked(String userId) {
    return _blockedUsers.contains(userId);
  }

  /// 차단 다이얼로그 표시
  void showBlockDialog({
    required BuildContext context,
    required String userName,
    required Function() onBlock,
    required double Function() getFontSizeMedium,
    required double Function() getFontSizeSmall,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('사용자 차단', style: TextStyle(fontSize: getFontSizeMedium())),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${userName}님을 차단하시겠습니까?',
                 style: TextStyle(fontSize: getFontSizeMedium())),
            const SizedBox(height: 8),
            Text('차단된 사용자의 메시지는 더 이상 보이지 않습니다.',
                 style: TextStyle(fontSize: getFontSizeSmall(), color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소', style: TextStyle(fontSize: getFontSizeMedium())),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onBlock();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('차단하기', style: TextStyle(fontSize: getFontSizeMedium(), color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 신고 다이얼로그 표시
  void showReportDialog({
    required BuildContext context,
    required String userName,
    required Function(String reason, String detail) onSubmit,
    required double Function() getFontSizeLarge,
    required double Function() getFontSizeMedium,
    required double Function() getFontSizeSmall,
  }) {
    final reportReasons = [
      '스팸 또는 광고',
      '욕설 또는 비하',
      '부적절한 내용',
      '개인정보 유출',
      '기타',
    ];

    String? selectedReason;
    final TextEditingController detailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('신고하기', style: TextStyle(fontSize: getFontSizeLarge())),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('신고 대상: $userName',
                     style: TextStyle(fontSize: getFontSizeMedium(), fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('신고 사유를 선택해주세요:',
                     style: TextStyle(fontSize: getFontSizeMedium())),
                const SizedBox(height: 8),
                ...reportReasons.map((reason) => RadioListTile<String>(
                  title: Text(reason, style: TextStyle(fontSize: getFontSizeSmall())),
                  value: reason,
                  groupValue: selectedReason,
                  onChanged: (value) => setState(() => selectedReason = value),
                )),
                const SizedBox(height: 16),
                TextField(
                  controller: detailController,
                  decoration: InputDecoration(
                    labelText: '상세 내용 (선택사항)',
                    border: OutlineInputBorder(),
                    hintText: '신고 사유를 자세히 설명해주세요',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('취소', style: TextStyle(fontSize: getFontSizeMedium())),
            ),
            ElevatedButton(
              onPressed: selectedReason != null ? () {
                onSubmit(selectedReason!, detailController.text);
                Navigator.of(context).pop();
              } : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('신고하기', style: TextStyle(fontSize: getFontSizeMedium(), color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
