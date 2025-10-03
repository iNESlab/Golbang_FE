import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/chat_room.dart';
import '../../models/event.dart';
import '../../utils/reponsive_utils.dart';
import '../../services/stomp_chat_service.dart';
import '../../global/PrivateClient.dart';
import 'dart:convert'; // Added for jsonDecode
import 'dart:developer'; // Added for log function
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Added for FlutterSecureStorage
import 'dart:convert' show base64Url, utf8; // Added for JWT decoding
import 'package:flutter/services.dart'; // Added for Clipboard


class ClubChatPage extends ConsumerStatefulWidget {
  final Event event;
  final ChatRoom? chatRoom;

  const ClubChatPage({
    super.key,
    required this.event,
    this.chatRoom,
  });

  @override
  ConsumerState<ClubChatPage> createState() => _ClubChatPageState();
}

class _ClubChatPageState extends ConsumerState<ClubChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  // STOMP WebSocket 서비스
  late StompChatService _stompService;
  
  // 연결 상태
  bool _isConnected = false;
  String _connectionStatus = '연결 중...';
  
  // 🔧 추가: 상세한 로딩 상태
  bool _isConnecting = true;
  bool _isLoadingMessages = false;
  
  // 🔧 추가: 현재 사용자 정보 (에코 방지용)
  String _currentUserName = '';
  String _currentUserId = '';  // 🔧 추가: 현재 사용자 ID
  
  // 🔧 추가: 고도화 기능을 위한 상태
  bool _isAdmin = false;  // 관리자 여부
  
  // 🔧 추가: 차단된 사용자 관리
  Set<String> _blockedUsers = {};
  Set<String> _showBlockedMessages = {};  // 차단된 메시지 중 보여줄 메시지 ID들
  Map<String, int> _messageReadCounts = {};  // 메시지별 읽은 사람 수
  Map<String, Map<String, int>> _messageReactions = {};  // 메시지별 반응 수
  
  // 🔧 추가: 고정된 메시지 (하나만)
  ChatMessage? _pinnedMessage;
  
  // 🔧 추가: 고정된 메시지 애니메이션
  late AnimationController _pinnedMessageAnimationController;
  late Animation<double> _pinnedMessageHeightAnimation;
  
  
  
  
  late double screenWidth;
  late double screenHeight;
  late Orientation orientation;
  late double fontSizeLarge;
  late double fontSizeMedium;
  late double fontSizeSmall;

  @override
  void initState() {
    super.initState();
    _stompService = StompChatService();
    
    // 🔧 추가: Club에서 관리자 정보 설정
    _isAdmin = widget.event.club?.isAdmin ?? false;
    log('🔧 initState에서 _isAdmin 설정: $_isAdmin');
    
    // 🔧 추가: 차단된 사용자 목록 로드
    log('🔧 initState에서 차단된 사용자 목록 로드 시작');
    _loadBlockedUsers();
    
    // 🔧 추가: 고정된 메시지 애니메이션 컨트롤러 초기화
    _pinnedMessageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _pinnedMessageHeightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pinnedMessageAnimationController,
      curve: Curves.easeInOut,
    ));
    
    
    // 🔧 추가: 스크롤 컨트롤러 초기화
    
    // 🔧 추가: 메시지 스트림 구독
    _stompService.messageStream.listen(
      (message) {
        log('📱 UI에서 메시지 수신: ${message.content}'); // 🔧 추가: 디버그 로그
        
        // 🔧 수정: 메시지 출처 구분 처리
        _onMessageReceived(message, isFromStomp: true);
      },
      onError: (error) {
        log('❌ 메시지 스트림 에러: $error'); // 🔧 추가: 디버그 로그
      },
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectToStomp();
      // 🔧 추가: 채팅방 진입 시 모든 메시지 읽음 상태 업데이트
      _markAllMessagesAsRead();
      // 🔧 추가: 클럽 멤버 수 로드
      _loadClubMemberCount();
      // 🔧 추가: 고정된 메시지 로드
      _loadPinnedMessages();
    });
  }

  // STOMP WebSocket 연결 (현재 비활성화)
  Future<void> _connectToStomp() async {
    try {
      log('🔌 STOMP 연결 시도 중...');
      setState(() {
        _isConnecting = true;
        _connectionStatus = '연결 중...';
      });
      
      // 🔧 추가: 실제 사용자 정보 가져오기
      final storage = const FlutterSecureStorage();
      final userEmail = await storage.read(key: 'LOGIN_ID');  // 이메일이 저장된 키
      
      // JWT 토큰에서 user_id 추출
      final accessToken = await storage.read(key: 'ACCESS_TOKEN');
      String? userId;
      if (accessToken != null) {
        try {
          final parts = accessToken.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64Url.normalize(payload);
            final resp = utf8.decode(base64Url.decode(normalized));
            final payloadMap = jsonDecode(resp);
            
            // 🔧 추가: JWT 페이로드 전체 출력
            log('🔍 JWT 페이로드 전체: $payloadMap');
            
            // 🔧 수정: user_id 사용 (기존 데이터와 호환)
            userId = payloadMap['user_id']?.toString() ?? payloadMap['id']?.toString();
            log('🔍 추출된 user_id: $userId');
            log('🔍 user_id 타입: ${userId.runtimeType}');
            log('🔍 user_id 길이: ${userId?.length}');
            
            // 🔧 추가: 다른 가능한 키들도 확인
            log('🔍 JWT에서 가능한 키들: ${payloadMap.keys.toList()}');
            if (payloadMap.containsKey('sub')) log('🔍 sub: ${payloadMap['sub']}');
            if (payloadMap.containsKey('email')) log('🔍 email: ${payloadMap['email']}');
            
          }
        } catch (e) {
          log('❌ JWT 토큰 파싱 실패: $e');
        }
      }
      
      log('👤 실제 사용자 정보: ID=$userId, Email=$userEmail');
      
      // Django 서버에 연결 시도 (사용자 정보 포함) - 모임 채팅방으로 연결
      final connected = await _stompService.connect(
        'club_${widget.event.club?.clubId}',
        userId: userId,
        userEmail: userEmail,
      );
      
      if (connected) {
        log('✅ Django 서버 연결 성공!');
        setState(() {
          _isConnected = true;
          _isConnecting = false;
          _connectionStatus = '연결됨';
          _isLoadingMessages = true; // 메시지 로딩 시작
        });
        
        // 🔧 수정: 백엔드에서 사용자 정보를 받을 때까지 대기
        // 사용자 정보는 백엔드에서 'user_info' 메시지로 전송됨
        log('👤 백엔드에서 사용자 정보 대기 중...');
        
        // 🔧 수정: 초기 메시지 로드 (한 번만)
        _loadInitialMessages();
        
      } else {
        log('❌ Django 서버 연결 실패, 예시 모드로 실행');
        setState(() {
          _isConnected = false;
          _isConnecting = false;
          _isLoadingMessages = false; // 🔧 추가: 메시지 로딩도 완료로 처리
          _connectionStatus = '예시 모드';
        });
        
        // 🔧 수정: 예시 모드에서도 고유 사용자 ID 생성
        final connectionId = DateTime.now().millisecondsSinceEpoch % 10000;
        _currentUserId = 'example_user_$connectionId';
        _currentUserName = '예시사용자_$connectionId';
        
        log('👤 예시 모드 사용자 설정: ID=$_currentUserId, 이름=$_currentUserName');
        
        // 🔧 수정: 예시 모드에서는 메시지 로드 안함 (STOMP 연결 실패 시)
        log('📚 예시 모드: 메시지 로드 건너뜀');
      }
    } catch (e) {
      log('❌ Django 서버 연결 실패: $e');
      setState(() {
        _isConnected = false;
        _isConnecting = false;
        _isLoadingMessages = false; // 🔧 추가: 메시지 로딩도 완료로 처리
        _connectionStatus = '예시 모드';
      });
      
      // 🔧 수정: 에러 발생 시에도 고유 사용자 ID 생성
      final connectionId = DateTime.now().millisecondsSinceEpoch % 10000;
      _currentUserId = 'error_user_$connectionId';
      _currentUserName = '에러사용자_$connectionId';
      
      log('👤 에러 모드 사용자 설정: ID=$_currentUserId, 이름=$_currentUserName');
      
      // 🔧 수정: 에러 시에도 메시지 로드 안함
      log('📚 에러 모드: 메시지 로드 건너뜀');
    }
  }
  
  // 메시지 수신 처리
  // ❗️ 이 함수를 완전히 교체했습니다.
  void _onMessageReceived(ChatMessage message, {bool isFromStomp = false}) {
    // 사용자 정보 메시지는 기존처럼 처리
    if (message.messageType == 'USER_INFO') {
      log('📨 USER_INFO 메시지 수신: ${message.content}');
      try {
        final userInfo = jsonDecode(message.content);
        log('📨 파싱된 사용자 정보: $userInfo');
        _onUserInfoReceived(userInfo);
        return;
      } catch (e) {
        log('❌ 사용자 정보 파싱 실패: $e');
        return;
      }
    }
    
    // 🔧 추가: 새로운 메시지 타입들 처리
    if (message.messageType == 'MESSAGE_HISTORY_BATCH' || message.messageType == 'message_history') {
      try {
        final data = jsonDecode(message.content);
        final messagesData = data['messages'] as List;
        final historyMessages = messagesData.map((msgData) {
          // 🔧 추가: 관리자 메시지 처리
          String content = msgData['content'];
          String messageType = msgData['message_type'];
          
          // TEXT 타입이지만 특수 메시지인 경우 처리
          if (messageType == 'TEXT' && content.startsWith('{"type":"')) {
            try {
              final specialData = jsonDecode(content);
              if (specialData['type'] == 'admin_message') {
                content = specialData['content'];
                messageType = 'ADMIN';
                // 관리자 이름도 업데이트
                if (specialData['sender_name'] != null) {
                  msgData['sender'] = specialData['sender_name'];
                }
                log('👑 히스토리에서 관리자 메시지 변환: $content (${msgData['sender']})');
              }
            } catch (e) {
              log('❌ 특수 메시지 파싱 실패: $e');
            }
          }
          
          return ChatMessage(
            messageId: msgData['id'],
            chatRoomId: 'current_room',
            senderId: msgData['sender_id'],
            senderName: msgData['sender'],
            content: content,
            messageType: messageType,
            timestamp: DateTime.parse(msgData['created_at']),
            isRead: false,
          );
        }).whereType<ChatMessage>().toList();
        _onMessageHistoryReceived(historyMessages);
        
        // 🔧 추가: 히스토리 로드 후 차단된 사용자 메시지 확인
        _checkBlockedMessagesAfterHistoryLoad();
        return;
      } catch (e) {
        log('❌ 히스토리 배치 파싱 실패: $e');
        return;
      }
    }
    
    // 🔧 추가: admin_message 타입 직접 처리 (STOMP 서비스에서 처리되지 않는 경우)
    if (message.content.startsWith('{"type":"admin_message"')) {
      try {
        final data = jsonDecode(message.content);
        if (data['type'] == 'admin_message') {
          log('👑 직접 관리자 메시지 처리: ${data['content']}');
          _onAdminMessageReceived(ChatMessage(
            messageId: DateTime.now().millisecondsSinceEpoch.toString(),
            chatRoomId: 'current_room',
            senderId: data['sender_id'] ?? 'admin',
            senderName: data['sender_name'] ?? data['sender'] ?? '관리자',
            content: data['content'],
            messageType: 'ADMIN',
            timestamp: DateTime.now(),
            isRead: false,
          ));
          return;
        }
      } catch (e) {
        log('❌ 관리자 메시지 파싱 실패: $e');
      }
    }
    
    
    if (message.messageType == 'ADMIN') {
      _onAdminMessageReceived(message);
      return;
    }
    
    
    if (message.messageType == 'MESSAGE_READ_UPDATE') {
      _onReadUpdateReceived(message);
      return;
    }
    
    if (message.messageType == 'MESSAGE_REACTION_UPDATE') {
      _onReactionUpdateReceived(message);
      return;
    }
    
    // 🔧 추가: SYSTEM 메시지 처리
    if (message.messageType == 'SYSTEM') {
      log('🔧 시스템 메시지 수신: ${message.content}');
      _messages.add(message);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      setState(() {}); // 🔧 최적화: setState() 최소화
      _scrollToBottom();
      return;
    }

    // 🔧 추가: 차단된 사용자 메시지 확인
    if (_blockedUsers.contains(message.senderId)) {
      log('🚫 차단된 사용자의 실시간 메시지 수신: ${message.senderName} (${message.senderId})');
    }

    // --- 핵심 로직 시작 ---

    // 1. 내가 보낸 메시지가 서버로부터 돌아온 경우 (Echo 처리)
    log('🔍 내가 보낸 메시지가 서버로부터 돌아온 경우: ${message.senderId} == ${_currentUserId}');
    log('🔍 타입 비교: ${message.senderId.runtimeType} vs ${_currentUserId.runtimeType}');
    log('🔍 문자열 비교: "${message.senderId.toString()}" == "${_currentUserId}"');
    log('🔍 비교 결과: ${message.senderId.toString() == _currentUserId}');
    if (isFromStomp && message.senderId.toString() == _currentUserId) {
      // messageId가 UUID 형식이 아닌 임시 메시지를 찾는다. (보통 timestamp로 되어 있음)
      final index = _messages.lastIndexWhere((m) =>
          m.senderId.toString() == _currentUserId && m.messageId.length < 36);

      if (index != -1) {
        // 임시 메시지를 서버가 보내준 진짜 메시지로 교체!
        log('🔄 에코 메시지 수신! 임시 메시지를 서버 버전으로 교체합니다: ${message.content}');
        _messages[index] = message;
      } else {
        // 교체할 임시 메시지가 없으면, 중복 확인 후 추가 (Fallback)
        final isDuplicate = _messages.any((m) => m.messageId == message.messageId);
        if (!isDuplicate) {
          log('⚠️ 임시 메시지를 못찾았지만 중복이 아니므로 추가: ${message.content}');
          _messages.add(message);
        }
      }
    } else {
      // 2. 다른 사람이 보낸 메시지 또는 히스토리 메시지
      // messageId를 기준으로 중복 여부를 확인한다.
      final isDuplicate = _messages.any((m) => m.messageId == message.messageId);
      if (!isDuplicate) {
        log('✅ 새 메시지 추가: ${message.content}');
        _messages.add(message);
      } else {
        log('🚫 중복 메시지(ID: ${message.messageId})는 무시합니다.');
      }
    }

    // 3. 모든 처리 후, 항상 최신순으로 정렬
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    // 🔧 추가: 메시지 읽음 상태 업데이트 (내가 보낸 메시지가 아닌 경우)
    if (message.senderId.toString() != _currentUserId && message.messageType != 'USER_INFO' && message.messageType != 'MESSAGE_HISTORY_BATCH') {
      _markMessageAsRead(message.messageId);
    }
    
    // --- 핵심 로직 끝 ---
    setState(() {}); // 🔧 최적화: setState() 최소화

    // 스크롤을 맨 아래로 이동
    _scrollToBottom();
  }
  
  // 🔧 추가: 메시지 히스토리 배치 처리
  void _onMessageHistoryReceived(List<ChatMessage> messages) {
    log('📚 메시지 히스토리 배치 처리: ${messages.length}개 메시지');
    
    // 메시지 로딩 완료 (빈 배열이어도 완료로 처리)
    setState(() {
      _isLoadingMessages = false;
    });
    
    setState(() {
      // 빈 메시지 목록도 정상 처리
      _messages = messages;
      
      // 기존 메시지와 새 메시지 합치기 (빈 배열인 경우 스킵)
      if (messages.isNotEmpty) {
        final existingIds = _messages.map((m) => m.messageId).toSet();
        final newMessages = messages.where((m) => !existingIds.contains(m.messageId)).toList();
        
        // 🔧 추가: ADMIN과 ANNOUNCEMENT 타입 메시지는 특별 처리
        for (final message in newMessages) {
        if (message.messageType == 'ADMIN') {
          log('👑 히스토리에서 관리자 메시지 발견: ${message.content}');
          _onAdminMessageReceived(message);
        } else if (message.messageType == 'TEXT' && message.content.startsWith('{"type":"admin_message"')) {
          // 🔧 추가: TEXT 타입이지만 관리자 메시지인 경우 처리
          try {
            final data = jsonDecode(message.content);
            if (data['type'] == 'admin_message') {
              log('👑 히스토리에서 TEXT 타입 관리자 메시지 발견: ${data['content']}');
              final adminMessage = ChatMessage(
                messageId: message.messageId,
                chatRoomId: message.chatRoomId,
                senderId: message.senderId,
                senderName: data['sender_name'] ?? data['sender'] ?? message.senderName,
                content: data['content'],
                messageType: 'ADMIN',
                timestamp: message.timestamp,
                isRead: message.isRead,
              );
              _onAdminMessageReceived(adminMessage);
              continue;
            }
          } catch (e) {
            log('❌ TEXT 타입 관리자 메시지 파싱 실패: $e');
          }
        } else {
          _messages.add(message);
        }
        }
      }
      
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      log('✅ 히스토리 메시지 ${messages.length}개 처리 완료');
    });
    
    // 스크롤을 맨 아래로 이동
    _scrollToBottom();
  }
  
  // 🔧 추가: 백엔드에서 받은 사용자 정보 처리
  void _onUserInfoReceived(Map<String, dynamic> userInfo) {
    log('👤 백엔드에서 사용자 정보 수신: $userInfo');
    log('👤 is_admin 값: ${userInfo['is_admin']} (타입: ${userInfo['is_admin'].runtimeType})');
    
    setState(() {
      _currentUserId = userInfo['user_id'] ?? 'unknown_user';
      _currentUserName = userInfo['user_name'] ?? 'Unknown User';
      _isAdmin = userInfo['is_admin'] ?? false;  // 🔧 추가: 관리자 여부
    });
    
    log('✅ 사용자 정보 설정 완료: ID=$_currentUserId, 이름=$_currentUserName, 관리자=$_isAdmin');
    log('✅ _currentUserId 타입: ${_currentUserId.runtimeType}');
    log('✅ _currentUserId 길이: ${_currentUserId.length}');
    log('✅ _isAdmin 상태: $_isAdmin');
  }
  
  // 🔧 추가: 관리자 메시지 처리
  void _onAdminMessageReceived(ChatMessage message) {
    log('👑 관리자 메시지 수신: ${message.content}');
    
    setState(() {
      // 🔧 추가: 중복 방지
      final existingIds = _messages.map((m) => m.messageId).toSet();
      if (!existingIds.contains(message.messageId)) {
        _messages.add(message);
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        log('✅ 관리자 메시지 추가: ${message.content}');
      } else {
        log('⚠️ 중복된 관리자 메시지 무시: ${message.content}');
      }
    });
    
    // 스크롤을 맨 아래로 이동
    _scrollToBottom();
  }
  
  
  // 🔧 추가: 읽음 상태 업데이트 처리
  void _onReadUpdateReceived(ChatMessage message) {
    try {
      final data = jsonDecode(message.content);
      final messageId = data['message_id'];
      final readCount = data['read_count'];
      
      log('👁️ 읽음 상태 업데이트: 메시지=$messageId, 읽은 사람 수=$readCount');
      
      setState(() {
        _messageReadCounts[messageId] = readCount;
      });
    } catch (e) {
      log('❌ 읽음 상태 파싱 실패: $e');
    }
  }
  
  // 🔧 추가: 반응 상태 업데이트 처리
  void _onReactionUpdateReceived(ChatMessage message) {
    try {
      final data = jsonDecode(message.content);
      final messageId = data['message_id'];
      final reactionCounts = Map<String, int>.from(data['reaction_counts']);
      
      log('😀 반응 상태 업데이트: 메시지=$messageId, 반응=$reactionCounts');
      
      setState(() {
        _messageReactions[messageId] = reactionCounts;
      });
    } catch (e) {
      log('❌ 반응 상태 파싱 실패: $e');
    }
  }
  
  // 연결 상태 변경 처리
  void _onConnectionStatusChanged(String status) {
    setState(() {
      switch (status) {
        case 'connected':
          _isConnected = true;
          _connectionStatus = '연결됨';
          break;
        case 'disconnected':
          _isConnected = false;
          _connectionStatus = '연결 해제됨';
          break;
        case 'error':
          _isConnected = false;
          _connectionStatus = '연결 에러';
          break;
      }
    });
  }

  void _loadInitialMessages() {
    // 예시 메시지 제거 - 깨끗한 채팅방 시작
    setState(() {
      _messages.clear();
    });
    
    log('📚 예시 메시지 제거 - 깨끗한 채팅방 시작');
  }



  // ❗️ 이 함수도 완전히 교체했습니다.
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    // ✨ 1. 서버 ID와 충돌하지 않도록 임시 ID로 timestamp를 사용
    final tempMessageId = DateTime.now().millisecondsSinceEpoch.toString();

    final message = ChatMessage(
      messageId: tempMessageId, // 임시 ID 사용
      chatRoomId: widget.event.eventId.toString(),
      senderId: _currentUserId,
      senderName: _currentUserName,
      content: _messageController.text.trim(),
      messageType: 'TEXT',
      timestamp: DateTime.now(),
      isRead: false,
    );

    // ✨ 2. 낙관적 UI 업데이트: UI에 임시 메시지를 즉시 추가
    _messages.add(message);
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    log('📤 (임시) 메시지 UI에 추가: ${message.content}');
    // 🔧 최적화: setState() 최소화로 성능 향상
    setState(() {});

    _messageController.clear();

    // 3. 실제 서버로 메시지 전송
    if (_isConnected) {
      log('📤 STOMP로 메시지 전송: ${message.content}');
      _stompService.sendMessage(message.content);
    }

    // 스크롤 로직 (기존과 동일)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 🔧 추가: 관리자 메시지 전송
  void _sendAdminMessage(String content) {
    if (content.trim().isEmpty) return;
    
    if (_isConnected) {
      _stompService.sendMessage(jsonEncode({
        'type': 'admin_message',
        'content': content,
      }));
      
      // 🔧 수정: 관리자 메시지는 낙관적 UI 업데이트 없이 서버 응답만 기다림
      log('👑 관리자 메시지 전송: $content (서버 응답 대기)');
    }
  }
  
  
  // 🔧 추가: 메시지 읽음 표시 (HTTP API 버전)
  Future<void> _markMessageAsRead(String messageId) async {
    try {
      final privateClient = PrivateClient();
      final response = await privateClient.dio.post(
        '/api/v1/chat/mark-read/',
        data: {
          'message_id': messageId,
        },
      );
      
      if (response.statusCode == 200) {
        log('✅ 메시지 읽음 상태 업데이트 완료: $messageId');
      } else {
        log('❌ 메시지 읽음 상태 업데이트 실패: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ 메시지 읽음 상태 업데이트 오류: $e');
    }
  }
  
  // 🔧 추가: 메시지 반응 추가
  void _addReaction(String messageId, String reaction) {
    if (_isConnected) {
      _stompService.sendMessage(jsonEncode({
        'type': 'reaction',
        'message_id': messageId,
        'reaction': reaction,
      }));
    }
    
    log('😀 반응 추가: $messageId -> $reaction');
  }
  
  // 🔧 추가: 관리자 도구 다이얼로그
  void _showAdminTools() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('관리자 도구', style: TextStyle(fontSize: fontSizeLarge)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.admin_panel_settings, color: Colors.orange),
              title: Text('관리자 메시지', style: TextStyle(fontSize: fontSizeMedium)),
              subtitle: Text('관리자 권한으로 메시지 전송', style: TextStyle(fontSize: fontSizeSmall)),
              onTap: () {
                Navigator.of(context).pop();
                _showAdminMessageDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('닫기', style: TextStyle(fontSize: fontSizeMedium)),
          ),
        ],
      ),
    );
  }
  
  // 🔧 추가: 관리자 메시지 다이얼로그
  void _showAdminMessageDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('관리자 메시지', style: TextStyle(fontSize: fontSizeLarge)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '관리자 메시지를 입력하세요...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소', style: TextStyle(fontSize: fontSizeMedium)),
          ),
          TextButton(
            onPressed: () {
              _sendAdminMessage(controller.text);
              Navigator.of(context).pop();
            },
            child: Text('전송', style: TextStyle(fontSize: fontSizeMedium)),
          ),
        ],
      ),
    );
  }
  

  @override
  void dispose() {
    // 안전한 순서로 정리
    _messageController.dispose();
    _scrollController.dispose();
    _pinnedMessageAnimationController.dispose();
    
    // 서비스들을 안전하게 정리
    try {
      _stompService.dispose();
    } catch (e) {
      log('StompService dispose 오류: $e');
    }
    
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    orientation = MediaQuery.of(context).orientation;
    fontSizeLarge = ResponsiveUtils.getLargeFontSize(screenWidth, orientation);
    fontSizeMedium = ResponsiveUtils.getMediumFontSize(screenWidth, orientation);
    fontSizeSmall = ResponsiveUtils.getSmallFontSize(screenWidth, orientation);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${widget.event.club?.name ?? '클럽'}',
              style: TextStyle(fontSize: fontSizeMedium, fontWeight: FontWeight.bold),
            ),
            Text(
              '멤버 ${_clubMemberCount}명',
              style: TextStyle(
                fontSize: fontSizeSmall,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showBottomSheetMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔧 추가: 고정된 메시지 표시 (하나만) - 앱바에 딱 붙여서 표시
          
          if (_pinnedMessage != null)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Column(
                children: [
                  // 접기/펼치기 헤더
                  GestureDetector(
                    onTap: () {
                      // 고정된 메시지 상세 화면으로 이동
                      _showPinnedMessageDetail();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        border: Border(
                          bottom: BorderSide(color: Colors.blue.shade200, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          // 핀 아이콘
                          Icon(Icons.push_pin, size: 16, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          
                          // 발신자 이름
                          Text(
                            _pinnedMessage!.senderName,
                            style: TextStyle(
                              fontSize: fontSizeMedium,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // 시간 정보
                          Text(
                            _formatTime(_pinnedMessage!.timestamp),
                            style: TextStyle(
                              fontSize: fontSizeSmall,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          
                          const SizedBox(width: 8),
                          
                        // 펼치기 아이콘
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: Colors.blue.shade600,
                        ),
                        ],
                      ),
                    ),
                  ),
                  
                  // 메시지 내용 (한 줄만 표시)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Text(
                      _pinnedMessage!.content,
                      style: TextStyle(
                        fontSize: fontSizeMedium,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                      maxLines: 1, // 한 줄만 표시
                      overflow: TextOverflow.ellipsis, // 한 줄 초과 시 ... 표시
                    ),
                  ),
                ],
              ),
            ),
          
          // 메시지 목록
          Expanded(
            child: _isConnecting || _isLoadingMessages
                ? _buildLoadingState()
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
          ),
          
          
          // 메시지 입력 영역
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요...',
                        hintStyle: TextStyle(fontSize: fontSizeMedium),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: 5, // 최대 5줄까지만 표시
                      minLines: 1, // 최소 1줄
                      textInputAction: TextInputAction.newline, // 엔터키로 줄바꿈
                      onSubmitted: (_) => _sendMessage(),
                      textCapitalization: TextCapitalization.sentences, // 문장 시작 대문자
                      keyboardType: TextInputType.multiline, // 여러 줄 입력 허용
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 메시지가 없습니다',
            style: TextStyle(
              fontSize: fontSizeMedium,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '첫 번째 메시지를 보내보세요!',
            style: TextStyle(
              fontSize: fontSizeSmall,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMyMessage, {bool isBlocked = false, bool isShowingBlocked = false}) {
    // 🔧 추가: 차단된 메시지 처리
    if (isBlocked && !isShowingBlocked) {
      return _buildBlockedMessagePlaceholder(message);
    }
    
    // 🔧 추가: 메시지 타입별 스타일 결정
    bool isAdmin = message.messageType == 'ADMIN';
    bool isAnnouncement = message.messageType == 'ANNOUNCEMENT';
    bool isSystem = message.messageType == 'SYSTEM';
    
    // 🔧 추가: 차단된 메시지가 보이는 상태일 때 특별한 스타일 적용
    bool showBlockedIndicator = isBlocked && isShowingBlocked;
    
    // 🔧 추가: 관리자 메시지 content 파싱
    String displayContent = message.content;
    if (isAdmin && message.content.startsWith('{') && message.content.endsWith('}')) {
      try {
        final jsonContent = jsonDecode(message.content);
        if (jsonContent is Map && jsonContent.containsKey('content')) {
          displayContent = jsonContent['content'].toString();
          log('🔍 메시지 빌드에서 관리자 메시지 파싱: $displayContent');
        }
      } catch (e) {
        log('⚠️ 메시지 빌드에서 JSON 파싱 실패: $e');
      }
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage && (!isBlocked || _showBlockedMessages.contains(message.messageId))) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: isAdmin 
                  ? Colors.orange.shade300
                  : isAnnouncement 
                      ? Colors.blue.shade300
                      : Colors.grey.shade300,
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0] : '?',
                style: TextStyle(fontSize: fontSizeSmall),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                log('🟢 onLongPress fired (isAdmin=$_isAdmin) for message ${message.messageId}');
                if (isBlocked && isShowingBlocked) {
                  // 차단된 메시지가 보이는 상태에서는 차단 해제 다이얼로그
                  _showUnblockDialog(message);
                } else {
                  // 일반 메시지 메뉴
                  _showMessageMenu(message);
                }
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: screenWidth * 0.7,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: showBlockedIndicator
                      ? Colors.red.shade50
                      : isSystem
                          ? Colors.orange.shade100
                          : isAdmin
                              ? Colors.orange.shade100
                              : isAnnouncement
                                  ? Colors.blue.shade100
                                  : isMyMessage
                                      ? Colors.green
                                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(18),
                  border: showBlockedIndicator
                      ? Border.all(color: Colors.red.shade300, width: 2)
                      : isAdmin 
                          ? Border.all(color: Colors.orange, width: 2)
                          : isAnnouncement
                              ? Border.all(color: Colors.blue, width: 2)
                              : message.isPinned
                                  ? Border.all(color: Colors.amber, width: 2)
                                  : null,
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔧 추가: 차단된 메시지 표시
                  if (showBlockedIndicator)
                    Container(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.block, size: 12, color: Colors.red.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '차단된 사용자의 메시지',
                            style: TextStyle(
                              fontSize: fontSizeSmall - 2,
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showBlockedMessages.remove(message.messageId);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '숨기기',
                                style: TextStyle(
                                  fontSize: fontSizeSmall - 3,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // 🔧 추가: 발신자 정보 (관리자/공지 표시) - 차단된 사용자는 숨김 (보기 모드에서는 표시)
                  if (!isMyMessage && !isSystem && (!isBlocked || _showBlockedMessages.contains(message.messageId)))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          if (isAdmin) 
                            Icon(Icons.admin_panel_settings, size: 16, color: Colors.orange.shade800),
                          if (isAnnouncement) 
                            Icon(Icons.announcement, size: 16, color: Colors.blue.shade800),
                          if (isAdmin || isAnnouncement) const SizedBox(width: 4),
                          Text(
                            message.senderName,
                            style: TextStyle(
                              fontSize: fontSizeSmall,
                              fontWeight: FontWeight.bold,
                              color: isAdmin 
                                  ? Colors.orange.shade800
                                  : isAnnouncement
                                      ? Colors.blue.shade800
                                      : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // 메시지 내용
                  Row(
                    children: [
                      Expanded(
                        child: isBlocked && !_showBlockedMessages.contains(message.messageId)
                          ? GestureDetector(
                              onTap: () => _toggleBlockedMessage(message),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade400, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade200,
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.block,
                                      size: 18,
                                      color: Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '차단된 사용자의 메시지입니다',
                                        style: TextStyle(
                                          fontSize: fontSizeSmall,
                                          color: Colors.grey.shade600,
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Text(
                                        '탭하여 보기',
                                        style: TextStyle(
                                          fontSize: fontSizeSmall - 2,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Text(
                              displayContent,
                              style: TextStyle(
                                fontSize: fontSizeMedium,
                                color: isSystem
                                    ? Colors.orange.shade800
                                    : isAdmin
                                        ? Colors.orange.shade800
                                        : isAnnouncement
                                            ? Colors.blue.shade800
                                            : isMyMessage
                                                ? Colors.white
                                                : Colors.black87,
                              ),
                            ),
                      ),
                      if (message.isPinned) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.push_pin,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // 🔧 추가: 시간과 읽음 표시
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: fontSizeSmall,
                          color: isSystem
                              ? Colors.orange.shade600
                              : isAdmin
                                  ? Colors.orange.shade600
                                  : isAnnouncement
                                      ? Colors.blue.shade600
                                      : isMyMessage
                                          ? Colors.white70
                                          : Colors.grey.shade600,
                        ),
                      ),
                      
                      // 🔧 추가: 읽은 사람 수 표시
                      if (_messageReadCounts.containsKey(message.messageId))
                        Row(
                          children: [
                            Icon(
                              Icons.done_all,
                              size: 14,
                              color: isMyMessage ? Colors.white70 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${_messageReadCounts[message.messageId]}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isMyMessage ? Colors.white70 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  
                  // 🔧 추가: 반응 표시
                  if (_messageReactions.containsKey(message.messageId))
                    _buildReactions(message.messageId),
                ],
              ),
            ),
            ),
          ),
          
          if (isMyMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                '나',
                style: TextStyle(fontSize: fontSizeSmall),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // 🔧 추가: 반응 표시 위젯
  Widget _buildReactions(String messageId) {
    final reactions = _messageReactions[messageId] ?? {};
    if (reactions.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: reactions.entries.map((entry) {
          return GestureDetector(
            onTap: () => _addReaction(messageId, entry.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${entry.key} ${entry.value}',
                style: TextStyle(fontSize: 10),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatTime(DateTime time) {
    // 🔧 개선: 명시적으로 로컬 시간으로 변환
    final localTime = time.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(localTime.year, localTime.month, localTime.day);
    
    if (messageDate == today) {
      return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return '어제 ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${localTime.month}/${localTime.day} ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    }
  }


  // 🔧 추가: 바텀시트 메뉴 표시
  void _showBottomSheetMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들 바
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // 메뉴 항목들
            if (_isAdmin) ...[
              _buildBottomSheetItem(
                icon: Icons.admin_panel_settings,
                title: '관리자 도구',
                color: Colors.orange,
                onTap: () {
                  Navigator.pop(context);
                  _showAdminTools();
                },
              ),
              const Divider(height: 1),
            ],
            
            _buildBottomSheetItem(
              icon: Icons.info_outline,
              title: '채팅방 정보',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                _showChatRoomInfo();
              },
            ),
            
            // 🔧 추가: 개발/테스트용 전체 차단 해제
            _buildBottomSheetItem(
              icon: Icons.delete_forever,
              title: '모든 차단 해제 (개발용)',
              color: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _clearAllBlockedUsers();
              },
            ),
            
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // 🔧 추가: 바텀시트 메뉴 아이템 빌더
  Widget _buildBottomSheetItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: fontSizeMedium,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  void _showChatRoomInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('채팅방 정보', style: TextStyle(fontSize: fontSizeLarge)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('이벤트: ${widget.event.eventTitle}', style: TextStyle(fontSize: fontSizeMedium)),
            const SizedBox(height: 8),
            Text('참가자 수: ${widget.event.participants.length}명', style: TextStyle(fontSize: fontSizeMedium)),
            const SizedBox(height: 8),
            Text('시작 시간: ${_formatTime(widget.event.startDateTime)}', style: TextStyle(fontSize: fontSizeMedium)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '현재는 임시 데이터를 사용합니다. 실제 채팅방 기능은 서버 준비 후 구현 예정입니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('닫기', style: TextStyle(fontSize: fontSizeMedium)),
          ),
        ],
      ),
    );
  }
  
  
  // 🔧 추가: 클럽 멤버 수 가져오기
  int _clubMemberCount = 0;
  
  // 🔧 추가: 고정된 메시지 펼침 상태
  bool _isPinnedMessageExpanded = false;
  
  // 🔧 추가: 고정된 메시지 상세 화면 표시
  void _showPinnedMessageDetail() {
    if (_pinnedMessage == null) return;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 핸들 바
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // 헤더
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.push_pin, size: 20, color: Colors.blue.shade600),
                    SizedBox(width: 8),
                    Text(
                      '고정된 메시지',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              
              // 메시지 내용
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 발신자 정보
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(
                              Icons.person,
                              color: Colors.blue.shade600,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _pinnedMessage!.senderName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                _formatTime(_pinnedMessage!.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      
                      // 메시지 내용
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          _pinnedMessage!.content,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _loadClubMemberCount() async {
    try {
      if (widget.event.club?.clubId != null) {
        final privateClient = PrivateClient();
        final response = await privateClient.get('/api/v1/clubs/${widget.event.club!.clubId}/');
        
        log('🔍 클럽 API 응답: ${response.statusCode}');
        log('🔍 클럽 API 데이터: ${response.data}');
        
        if (response.statusCode == 200) {
          final responseData = response.data;
          if (responseData is Map && responseData.containsKey('data')) {
            final data = responseData['data'];
            if (data is Map && data.containsKey('members_count')) {
              setState(() {
                _clubMemberCount = data['members_count'] ?? 0;
              });
              log('✅ 멤버 수 로딩 성공: ${_clubMemberCount}명');
            } else if (data is Map && data.containsKey('members')) {
              // members 배열이 있는 경우
              setState(() {
                _clubMemberCount = (data['members'] as List).length;
              });
              log('✅ 멤버 수 로딩 성공 (배열): ${_clubMemberCount}명');
            } else {
              log('❌ 멤버 수 필드를 찾을 수 없음');
              log('❌ 사용 가능한 필드: ${data.keys.toList()}');
              setState(() {
                _clubMemberCount = widget.event.participants.length;
              });
            }
          } else {
            log('❌ API 응답에 data 필드가 없음');
            log('❌ 응답 구조: ${responseData.keys.toList()}');
            setState(() {
              _clubMemberCount = widget.event.participants.length;
            });
          }
        }
      }
    } catch (e) {
      log('❌ 클럽 멤버 수 로딩 오류: $e');
      // 오류 시 기본값 사용
      setState(() {
        _clubMemberCount = widget.event.participants.length;
      });
    }
  }
  
  // 🔧 추가: 고정된 메시지 가져오기 (하나만)
  Future<void> _loadPinnedMessages() async {
    try {
      log('🔍 고정된 메시지 로딩 시작');
      log('🔍 _pinnedMessage 현재 상태: $_pinnedMessage');
      log('🔍 widget.chatRoom: ${widget.chatRoom}');
      
      // chatRoomId 가져오기 (여러 방법 시도)
      String? chatRoomId;
      if (widget.chatRoom?.chatRoomId != null) {
        chatRoomId = widget.chatRoom!.chatRoomId;
        log('🔍 chatRoomId (from widget.chatRoom): $chatRoomId');
      } else {
        // chatRoom이 없으면 클럽 ID로 실제 채팅방 ID 조회
        if (widget.event.club?.clubId != null) {
          try {
            final privateClient = PrivateClient();
            final clubResponse = await privateClient.get('/api/v1/clubs/${widget.event.club!.clubId}/');
            if (clubResponse.statusCode == 200) {
              final clubData = clubResponse.data;
              if (clubData is Map && clubData.containsKey('data')) {
                final clubInfo = clubData['data'];
                // 클럽 ID를 그대로 사용 (백엔드에서 클럽 ID로 채팅방을 찾음)
                chatRoomId = widget.event.club!.clubId.toString();
                log('🔍 chatRoomId (from club ID): $chatRoomId');
                log('🔍 widget.event.club: ${widget.event.club}');
                log('🔍 widget.event.club!.clubId: ${widget.event.club!.clubId}');
              }
            }
          } catch (e) {
            log('❌ 클럽 정보 조회 실패: $e');
          }
        }
        
        if (chatRoomId == null) {
          log('❌ chatRoomId를 찾을 수 없습니다');
          return;
        }
      }
      
      final privateClient = PrivateClient();
      final response = await privateClient.get(
        '/api/v1/chat/pinned-messages/',
        queryParameters: {'chat_room_id': chatRoomId},
      );
      
      log('🔍 고정된 메시지 API 응답: ${response.statusCode}');
      log('🔍 고정된 메시지 API 데이터: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('messages')) {
          final messagesData = data['messages'] as List;
          log('🔍 고정된 메시지 개수: ${messagesData.length}');
          if (messagesData.isNotEmpty) {
            // 가장 최근 고정된 메시지 하나만 가져오기
            final msgData = messagesData.first;
            log('🔍 고정된 메시지 데이터: $msgData');
            // 메시지 content 파싱 (JSON 형태인 경우)
            String messageContent = msgData['content'];
            log('🔍 원본 메시지 content: $messageContent');
            log('🔍 메시지 타입: ${msgData['message_type']}');
            
            // JSON 형태인지 확인하고 파싱 시도
            if (messageContent.startsWith('{') && messageContent.endsWith('}')) {
              log('🔍 JSON 형태 감지, 파싱 시도');
              try {
                final jsonContent = jsonDecode(messageContent);
                log('🔍 JSON 파싱 성공: $jsonContent');
                if (jsonContent is Map && jsonContent.containsKey('content')) {
                  messageContent = jsonContent['content'].toString();
                  log('🔍 파싱된 content: $messageContent');
                } else {
                  log('⚠️ JSON에 content 필드가 없음');
                }
              } catch (e) {
                log('⚠️ JSON 파싱 실패: $e');
                log('⚠️ 원본 content: $messageContent');
              }
            } else {
              log('🔍 JSON 형태가 아님, 그대로 사용');
            }
            
            setState(() {
              _pinnedMessage = ChatMessage(
                messageId: msgData['id'],
                chatRoomId: 'current_room',
                senderId: msgData['sender_id'],
                senderName: msgData['sender'],
                content: messageContent,
                messageType: msgData['message_type'],
                timestamp: DateTime.parse(msgData['created_at']),
                isRead: false,
                isPinned: true,
              );
            });
            log('✅ 고정된 메시지 설정 완료: ${_pinnedMessage!.content}');
            log('✅ _pinnedMessage 업데이트 후: $_pinnedMessage');
          } else {
            log('ℹ️ 고정된 메시지가 없습니다');
            setState(() {
              _pinnedMessage = null;
            });
          }
        } else {
          log('❌ 응답에 messages 필드가 없습니다');
          log('❌ 사용 가능한 필드: ${data.keys.toList()}');
        }
      } else {
        log('❌ API 응답 실패: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ 고정된 메시지 로딩 오류: $e');
    }
  }

  // 🔧 추가: 로딩 상태 UI
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isConnecting) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '채팅방에 연결 중...',
              style: TextStyle(
                fontSize: fontSizeMedium,
                color: Colors.grey[600],
              ),
            ),
          ] else if (_isLoadingMessages) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '메시지를 불러오는 중...',
              style: TextStyle(
                fontSize: fontSizeMedium,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🔧 추가: 스크롤을 맨 아래로 이동 (reverse: true이므로 0이 맨 아래)
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // reverse: true일 때 0이 맨 아래
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // 🔧 추가: 메시지 메뉴 표시
  void _showMessageMenu(ChatMessage message) {
    log('🔧 _showMessageMenu 호출됨 - _isAdmin: $_isAdmin, messageId: ${message.messageId}');
    
    // 🔧 추가: 관리자 메시지는 항상 다른 사람의 메시지로 처리 (내가 보낸 것이라도)
    final isMyMessage = message.messageType == 'ADMIN' ? false : message.senderId.toString() == _currentUserId;
    
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 관리자 전용 기능들
              if (_isAdmin) ...[
                ListTile(
                  leading: Icon(
                    message.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                    color: Colors.amber,
                  ),
                  title: Text(message.isPinned ? '고정 해제' : '메시지 고정'),
                  onTap: () {
                    Navigator.pop(context);
                    _toggleMessagePin(message.messageId);
                  },
                ),
                const Divider(),
              ],
              
              // 일반 사용자 기능들
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.blue),
                title: const Text('메시지 복사'),
                onTap: () {
                  Navigator.pop(context);
                  _copyMessage(message.content);
                },
              ),
              
              // 다른 사람의 메시지에만 신고/차단 옵션 표시
              if (!isMyMessage) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.red),
                  title: const Text('신고하기'),
                  onTap: () {
                    Navigator.pop(context);
                    _showReportDialog(message);
                  },
                ),
                 // 🔧 추가: 이미 차단된 사용자가 아닌 경우에만 차단 옵션 표시
                 if (!_blockedUsers.contains(message.senderId)) ...[
                   const Divider(),
                   ListTile(
                     leading: const Icon(Icons.block, color: Colors.orange),
                     title: const Text('사용자 차단'),
                     onTap: () {
                       Navigator.pop(context);
                       _showBlockUserDialog(message);
                     },
                   ),
                 ],
              ],
            ],
          ),
        );
      },
    );
  }

  // 🔧 추가: 메시지 고정/해제
  Future<void> _toggleMessagePin(String messageId) async {
    try {
      final privateClient = PrivateClient();
      final response = await privateClient.post(
        '/api/v1/chat/toggle-pin/',
        data: {
          'message_id': messageId,
        },
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final isPinned = data['is_pinned'] ?? false;
        
        // 로컬 메시지 상태 업데이트 (하나만 고정되도록)
        setState(() {
          // 먼저 모든 메시지의 고정 상태를 해제
          for (int i = 0; i < _messages.length; i++) {
            if (_messages[i].isPinned) {
              final message = _messages[i];
              _messages[i] = ChatMessage(
                messageId: message.messageId,
                chatRoomId: message.chatRoomId,
                senderId: message.senderId,
                senderName: message.senderName,
                senderProfileImage: message.senderProfileImage,
                messageType: message.messageType,
                content: message.content,
                timestamp: message.timestamp,
                isRead: message.isRead,
                isPinned: false, // 모든 고정 해제
              );
            }
          }
          
          // 해당 메시지만 고정 상태 설정
          final messageIndex = _messages.indexWhere((m) => m.messageId == messageId);
          if (messageIndex != -1) {
            final message = _messages[messageIndex];
            _messages[messageIndex] = ChatMessage(
              messageId: message.messageId,
              chatRoomId: message.chatRoomId,
              senderId: message.senderId,
              senderName: message.senderName,
              senderProfileImage: message.senderProfileImage,
              messageType: message.messageType,
              content: message.content,
              timestamp: message.timestamp,
              isRead: message.isRead,
              isPinned: isPinned,
            );
          }
        });
        
        log('✅ 메시지 고정 상태 업데이트: ${isPinned ? "고정" : "고정 해제"}');
        
        // 🔧 추가: 고정된 메시지 다시 로드
        await _loadPinnedMessages();
        
        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? '메시지 고정 상태가 변경되었습니다'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        log('❌ 메시지 고정 상태 업데이트 실패: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메시지 고정 상태 변경에 실패했습니다'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      log('❌ 메시지 고정 상태 업데이트 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('메시지 고정 상태 변경 중 오류가 발생했습니다'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // 🔧 추가: 모든 메시지 읽음 상태 업데이트
  Future<void> _markAllMessagesAsRead() async {
    try {
      final privateClient = PrivateClient();
      final response = await privateClient.dio.post(
        '/api/v1/chat/mark-all-read/',
        data: {
          'chat_room_id': widget.event.eventId.toString(),
        },
      );
      
      if (response.statusCode == 200) {
        log('✅ 모든 메시지 읽음 상태 업데이트 완료');
        // 모든 메시지를 읽음 상태로 표시
        setState(() {
          for (int i = 0; i < _messages.length; i++) {
            _messages[i] = ChatMessage(
              messageId: _messages[i].messageId,
              chatRoomId: _messages[i].chatRoomId,
              senderId: _messages[i].senderId,
              senderName: _messages[i].senderName,
              senderProfileImage: _messages[i].senderProfileImage,
              messageType: _messages[i].messageType,
              content: _messages[i].content,
              timestamp: _messages[i].timestamp,
              isRead: true, // 읽음 상태로 업데이트
            );
          }
        });
      } else {
        log('❌ 모든 메시지 읽음 상태 업데이트 실패: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ 모든 메시지 읽음 상태 업데이트 오류: $e');
    }
  }
  
  // 이벤트가 진행 중인지 확인하는 메서드
  bool _isEventInProgress() {
    final now = DateTime.now();
    final startTime = widget.event.startDateTime;
    final endTime = widget.event.endDateTime;
    
    // 이벤트 시작 30분 전부터 종료 시간까지를 진행 중으로 간주
    final broadcastStartTime = startTime.subtract(Duration(minutes: 30));
    
    return now.isAfter(broadcastStartTime) && now.isBefore(endTime);
  }


  
  // 🔧 추가: 메시지 복사
  void _copyMessage(String message) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('메시지가 복사되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // 🔧 추가: 신고 다이얼로그
  void _showReportDialog(ChatMessage message) {
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
          title: Text('신고하기', style: TextStyle(fontSize: fontSizeLarge)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('신고 대상: ${message.senderName}', 
                     style: TextStyle(fontSize: fontSizeMedium, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('신고 사유를 선택해주세요:', 
                     style: TextStyle(fontSize: fontSizeMedium)),
                const SizedBox(height: 8),
                ...reportReasons.map((reason) => RadioListTile<String>(
                  title: Text(reason, style: TextStyle(fontSize: fontSizeSmall)),
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
              child: Text('취소', style: TextStyle(fontSize: fontSizeMedium)),
            ),
            ElevatedButton(
              onPressed: selectedReason != null ? () {
                Navigator.of(context).pop();
                _submitReport(message, selectedReason!, detailController.text);
              } : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('신고하기', style: TextStyle(fontSize: fontSizeMedium, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // 🔧 추가: 신고 제출
  Future<void> _submitReport(ChatMessage message, String reason, String detail) async {
    try {
      final privateClient = PrivateClient();
      
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
      final response = await privateClient.post(
        '/api/v1/chat/report-message/',
        data: {
          'message_id': message.messageId,
          'report_type': reportType,
          'reason': reason,
          'detail': detail,
        },
      );
      
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('신고가 접수되었습니다. 검토 후 조치하겠습니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('신고 제출 실패');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('신고 접수 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // 🔧 추가: 사용자 차단 다이얼로그
  void _showBlockUserDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('사용자 차단', style: TextStyle(fontSize: fontSizeLarge)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${message.senderName}님을 차단하시겠습니까?', 
                 style: TextStyle(fontSize: fontSizeMedium)),
            const SizedBox(height: 8),
            Text('차단된 사용자의 메시지는 더 이상 보이지 않습니다.', 
                 style: TextStyle(fontSize: fontSizeSmall, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소', style: TextStyle(fontSize: fontSizeMedium)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _blockUser(message);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('차단하기', style: TextStyle(fontSize: fontSizeMedium, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🔧 추가: 차단된 메시지 플레이스홀더
  Widget _buildBlockedMessagePlaceholder(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '차단된 메시지입니다',
                    style: TextStyle(
                      fontSize: fontSizeSmall,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showBlockedMessages.add(message.messageId);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '보기',
                        style: TextStyle(
                          fontSize: fontSizeSmall - 2,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 추가: 히스토리 로드 후 차단된 메시지 확인
  void _checkBlockedMessagesAfterHistoryLoad() {
    if (_blockedUsers.isEmpty) return;
    
    log('🔧 히스토리 로드 후 차단된 메시지 확인 시작...');
    bool hasBlockedMessages = false;
    
    for (var message in _messages) {
      if (_blockedUsers.contains(message.senderId)) {
        log('🚫 차단된 사용자의 메시지 발견: ${message.senderName} (${message.senderId}) - ${message.content.substring(0, 20)}...');
        hasBlockedMessages = true;
      }
    }
    
    if (hasBlockedMessages) {
      log('🔧 차단된 메시지가 있어서 UI 새로고침 실행');
      setState(() {}); // UI 새로고침으로 차단된 메시지 표시
    }
  }

  // 🔧 추가: 서버와 로컬 모든 차단 해제 (개발/테스트용)
  Future<void> _clearAllBlockedUsers() async {
    try {
      final privateClient = PrivateClient();
      log('🗑️ 서버의 모든 차단 해제 시작...');
      
      // 서버에서 모든 차단 해제
      final response = await privateClient.delete('/api/v1/chat/clear-blocked-users/');
      
      if (response.statusCode == 200) {
        log('✅ 서버에서 모든 차단 해제 완료: ${response.data['message']}');
        
        // 로컬 저장소도 초기화
        final storage = FlutterSecureStorage();
        await storage.delete(key: 'blocked_users');
        log('🗑️ 로컬 저장소도 초기화 완료');
        
        setState(() {
          _blockedUsers.clear();
          _showBlockedMessages.clear();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('모든 차단이 해제되었습니다.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('서버에서 차단 해제 실패');
      }
    } catch (e) {
      log('❌ 전체 차단 해제 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('차단 해제 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // 🔧 추가: 차단된 사용자 로컬 저장소만 초기화 (개발/테스트용)
  Future<void> _clearBlockedUsersStorage() async {
    try {
      final storage = FlutterSecureStorage();
      await storage.delete(key: 'blocked_users');
      log('🗑️ 차단된 사용자 로컬 저장소 초기화 완료');
      
      setState(() {
        _blockedUsers.clear();
        _showBlockedMessages.clear();
      });
    } catch (e) {
      log('❌ 차단된 사용자 저장소 초기화 실패: $e');
    }
  }

  // 🔧 추가: 서버에서 차단된 사용자 목록 동기화
  Future<void> _syncBlockedUsersFromServer() async {
    try {
      final privateClient = PrivateClient();
      log('🔄 서버에서 차단된 사용자 목록 동기화 시작...');
      
      final response = await privateClient.get('/api/v1/chat/blocked-users/');
      
      if (response.statusCode == 200) {
        final data = response.data;
        final blockedUsersData = data['blocked_users'] as List;
        
        // 서버에서 가져온 차단된 사용자 ID 목록
        final serverBlockedUsers = blockedUsersData
            .map((user) => user['user_id'].toString())
            .toSet();
        
        log('🔄 서버에서 가져온 차단된 사용자: $serverBlockedUsers');
        
        // 로컬 저장소에 저장
        final storage = FlutterSecureStorage();
        await storage.write(key: 'blocked_users', value: jsonEncode(serverBlockedUsers.toList()));
        
        setState(() {
          _blockedUsers = serverBlockedUsers;
        });
        
        log('✅ 서버와 로컬 차단 목록 동기화 완료');
        
        // 메시지가 이미 로드된 경우 차단된 메시지 확인
        if (_messages.isNotEmpty) {
          log('🔧 동기화 후 차단된 메시지 확인...');
          _checkBlockedMessagesAfterHistoryLoad();
        }
      } else {
        log('⚠️ 서버 동기화 실패, 로컬 저장소에서 로드');
        await _loadBlockedUsersFromLocal();
      }
    } catch (e) {
      log('❌ 서버 동기화 실패: $e, 로컬 저장소에서 로드');
      await _loadBlockedUsersFromLocal();
    }
  }

  // 🔧 추가: 로컬 저장소에서 차단된 사용자 목록 로드
  Future<void> _loadBlockedUsersFromLocal() async {
    try {
      final storage = FlutterSecureStorage();
      final blockedUsers = await storage.read(key: 'blocked_users') ?? '[]';
      final List<dynamic> blockedList = jsonDecode(blockedUsers);
      
      setState(() {
        _blockedUsers = Set<String>.from(blockedList);
      });
      
      log('🔧 로컬에서 차단된 사용자 목록 로드: $_blockedUsers');
      
      // 메시지가 이미 로드된 경우 차단된 메시지 확인
      if (_messages.isNotEmpty) {
        log('🔧 현재 메시지 중 차단된 사용자 메시지 확인...');
        _checkBlockedMessagesAfterHistoryLoad();
      }
      
    } catch (e) {
      log('❌ 로컬 차단된 사용자 목록 로드 실패: $e');
    }
  }

  // 🔧 추가: 차단된 사용자 목록 로드 (서버 동기화 우선)
  Future<void> _loadBlockedUsers() async {
    await _syncBlockedUsersFromServer();
  }

  // 🔧 추가: 사용자 차단
  Future<void> _blockUser(ChatMessage message) async {
    try {
      // 🔧 추가: 이미 차단된 사용자인지 확인
      if (_blockedUsers.contains(message.senderId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${message.senderName}님은 이미 차단된 사용자입니다.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      
      final privateClient = PrivateClient();
      
      // 백엔드 API로 사용자 차단
      final response = await privateClient.post(
        '/api/v1/chat/block-user/',
        data: {
          'blocked_user_id': message.senderId,
          'reason': '사용자 요청에 의한 차단',
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // 차단된 사용자 ID를 로컬에 저장
        final storage = FlutterSecureStorage();
        final blockedUsers = await storage.read(key: 'blocked_users') ?? '[]';
        final List<dynamic> blockedList = jsonDecode(blockedUsers);
        
        if (!blockedList.contains(message.senderId)) {
          blockedList.add(message.senderId);
          await storage.write(key: 'blocked_users', value: jsonEncode(blockedList));
        }
        
        // UI 새로고침 및 차단된 사용자 목록 업데이트
        setState(() {
          _blockedUsers.add(message.senderId);
          // 차단된 메시지를 보기 모드에서 제거 (즉시 숨김 처리)
          _showBlockedMessages.removeWhere((messageId) {
            final msg = _messages.firstWhere((m) => m.messageId == messageId, orElse: () => message);
            return msg.senderId == message.senderId;
          });
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${message.senderName}님을 차단했습니다.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        } else if (response.statusCode == 500 && response.data != null && 
                   response.data.toString().contains('Duplicate entry')) {
          // 🔧 추가: 이미 차단된 사용자 에러 처리 (서버에서 중복 에러)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${message.senderName}님은 이미 차단된 사용자입니다.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // 로컬 상태도 업데이트 (서버와 동기화)
          setState(() {
            _blockedUsers.add(message.senderId);
            _showBlockedMessages.removeWhere((messageId) {
              final msg = _messages.firstWhere((m) => m.messageId == messageId, orElse: () => message);
              return msg.senderId == message.senderId;
            });
          });
          
          // 로컬 저장소에도 추가
          final storage = FlutterSecureStorage();
          final blockedUsers = await storage.read(key: 'blocked_users') ?? '[]';
          final List<dynamic> blockedList = jsonDecode(blockedUsers);
          if (!blockedList.contains(message.senderId)) {
            blockedList.add(message.senderId);
            await storage.write(key: 'blocked_users', value: jsonEncode(blockedList));
          }
        } else {
          throw Exception('차단 요청 실패: ${response.statusCode}');
        }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('차단 처리 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // 🔧 추가: 차단된 사용자 확인
  Future<bool> _isUserBlocked(String userId) async {
    try {
      final storage = FlutterSecureStorage();
      final blockedUsers = await storage.read(key: 'blocked_users') ?? '[]';
      final List<dynamic> blockedList = jsonDecode(blockedUsers);
      return blockedList.contains(userId);
    } catch (e) {
      return false;
    }
  }

  // 🔧 추가: 차단된 사용자 메시지 필터링 (차단된 메시지는 표시하되 내용을 숨김)
  Future<List<ChatMessage>> _getFilteredMessages() async {
    // 차단된 사용자의 메시지도 표시하되, 내용을 숨기기 위해 모든 메시지를 반환
    return _messages;
  }

  // 🔧 최적화: 메시지 리스트 빌더 (FutureBuilder 제거로 성능 향상)
  Widget _buildMessageList() {
    // 🔧 추가: 모든 메시지 표시 (차단된 메시지는 다르게 렌더링)
    final visibleMessages = _messages;
    
    return ListView.builder(
      key: ValueKey(visibleMessages.length), // 🔧 추가: 보이는 메시지 개수 변경 시에만 리빌드
      controller: _scrollController,
      reverse: true, // 🔧 추가: 맨 아래에서 시작
      padding: const EdgeInsets.all(16),
      itemCount: visibleMessages.length,
      itemBuilder: (context, index) {
        final message = visibleMessages[visibleMessages.length - 1 - index];
        // 🔧 수정: 실제 사용자 ID로 비교 (문자열 비교)
        // log('🎨 UI 메시지 비교: senderId="${message.senderId}" (${message.senderId.runtimeType}) vs currentUserId="$_currentUserId" (${_currentUserId.runtimeType})');
        // 🔧 추가: 관리자 메시지는 항상 왼쪽에 표시 (내가 보낸 것이라도)
        final isMyMessage = message.messageType == 'ADMIN' ? false : message.senderId.toString() == _currentUserId;
        // log('🎨 UI 비교 결과: $isMyMessage (관리자 메시지: ${message.messageType == 'ADMIN'})');
        
        final isBlocked = _blockedUsers.contains(message.senderId);
        final isShowingBlocked = _showBlockedMessages.contains(message.messageId);
        
        // 🔧 추가: 차단된 메시지 디버그 로그
        if (isBlocked) {
          log('🚫 UI 렌더링: 차단된 메시지 - ${message.senderName} (${message.senderId}), 보기모드: $isShowingBlocked');
        }
        
        return _buildMessageBubble(message, isMyMessage, isBlocked: isBlocked, isShowingBlocked: isShowingBlocked);
      },
    );
  }

  // 🔧 추가: 메시지가 차단된 사용자의 것인지 확인
  Future<bool> _isMessageFromBlockedUser(ChatMessage message) async {
    return await _isUserBlocked(message.senderId);
  }

  // 🔧 추가: 차단된 메시지 토글 (탭으로 원본 메시지 보기/숨기기)
  void _toggleBlockedMessage(ChatMessage message) {
    setState(() {
      if (_showBlockedMessages.contains(message.messageId)) {
        _showBlockedMessages.remove(message.messageId);
      } else {
        _showBlockedMessages.add(message.messageId);
      }
    });
  }

  // 🔧 추가: 차단 해제 다이얼로그
  void _showUnblockDialog(ChatMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('차단된 사용자', style: TextStyle(fontSize: fontSizeLarge)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${message.senderName}님의 메시지를 보시겠습니까?', 
                 style: TextStyle(fontSize: fontSizeMedium)),
            const SizedBox(height: 8),
            Text('차단을 해제하면 해당 사용자의 메시지를 다시 볼 수 있습니다.', 
                 style: TextStyle(fontSize: fontSizeSmall, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('취소', style: TextStyle(fontSize: fontSizeMedium)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _unblockUser(message);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('차단 해제', style: TextStyle(fontSize: fontSizeMedium, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🔧 추가: 사용자 차단 해제
  Future<void> _unblockUser(ChatMessage message) async {
    try {
      log('🔓 차단 해제 시작: ${message.senderName} (${message.senderId})');
      
      final privateClient = PrivateClient();
      
      // 백엔드 API로 사용자 차단 해제
      log('🔓 차단 해제 API 호출 중...');
      final response = await privateClient.post(
        '/api/v1/chat/unblock-user/',
        data: {
          'blocked_user_id': message.senderId,
        },
      );
      
      log('🔓 차단 해제 응답: ${response.statusCode}');
      log('🔓 차단 해제 응답 데이터: ${response.data}');
      
      if (response.statusCode == 200) {
        // 로컬 저장소에서 차단된 사용자 제거
        final storage = FlutterSecureStorage();
        final blockedUsers = await storage.read(key: 'blocked_users') ?? '[]';
        final List<dynamic> blockedList = jsonDecode(blockedUsers);
        blockedList.remove(message.senderId);
        await storage.write(key: 'blocked_users', value: jsonEncode(blockedList));
        
        // UI 새로고침 및 차단된 사용자 목록 업데이트
        setState(() {
          _blockedUsers.remove(message.senderId);
          // 해당 사용자의 모든 메시지를 보기 모드에서 제거
          _showBlockedMessages.removeWhere((messageId) {
            final msg = _messages.firstWhere((m) => m.messageId == messageId, orElse: () => message);
            return msg.senderId == message.senderId;
          });
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${message.senderName}님의 차단을 해제했습니다.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('차단 해제 요청 실패');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('차단 해제 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
  
}


