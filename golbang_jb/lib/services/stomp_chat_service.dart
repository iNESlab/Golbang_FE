import 'dart:convert';
import 'dart:async';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/chat_room.dart';

class StompChatService {
  WebSocketChannel? _channel;
  final StreamController<ChatMessage> _messageController = StreamController<ChatMessage>.broadcast();
  final StreamController<String> _connectionController = StreamController<String>.broadcast();
  
  // WebSocket 서버 URL (환경변수 사용)
  String get _serverUrl {
    // 예: wsHost = wss://dev.golf-bang.store 혹은 ws://localhost:8000
    final raw = dotenv.env['WS_HOST'];
    log('🔍 WS_HOST 환경변수: $raw');

    // 환경변수가 없으면 로컬 기본값으로 대체
    if (raw == null || raw.isEmpty) {
      log('⚠️ WS_HOST가 설정되어 있지 않습니다. 기본 ws://localhost:8000 사용');
      return 'ws://localhost:8000/ws/chat/';
    }

    // 끝에 슬래시 제거
    final cleaned = raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;

    // 이미 /ws/chat 포함 여부 방지하고 경로만 붙이기
    return '$cleaned/ws/chat/';
  }
  
  // 🔧 추가: 연결 관리 변수들
  String? _currentChatRoomId;
  String? _currentUserId;
  String? _currentUserEmail;
  bool _isConnected = false;
  bool _isReconnecting = false;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const int _reconnectDelay = 5; // 초 (더 관대하게)
  DateTime? _lastMessageTime;
  
  StompChatService() {
    // 앱 생명주기 감지
    SystemChannels.lifecycle.setMessageHandler(_handleAppLifecycle);
  }
  
  Stream<ChatMessage> get messageStream => _messageController.stream;
  Stream<String> get connectionStream => _connectionController.stream;
  
  // 🔧 추가: 앱 생명주기 처리
  Future<String?> _handleAppLifecycle(String? message) async {
    log('📱 앱 생명주기 변경: $message');
    
    if (message == 'AppLifecycleState.resumed') {
      // 포그라운드로 돌아올 때
      log('🔄 앱이 포그라운드로 돌아옴 - 연결 상태 확인');
      await _checkAndReconnect();
    } else if (message == 'AppLifecycleState.paused') {
      // 백그라운드로 갈 때
      log('⏸️ 앱이 백그라운드로 이동');
    }
    
    return null;
  }
  
  // 🔧 추가: 연결 상태 확인 및 재연결
  Future<void> _checkAndReconnect() async {
    if (!_isConnected && _currentChatRoomId != null) {
      log('🔄 연결이 끊어진 상태 - 재연결 시도');
      await _performReconnection();
    } else if (_isConnected) {
      // 연결되어 있다면 최신 메시지 요청
      log('📚 연결 상태 양호 - 최신 메시지 동기화');
      await _syncLatestMessages();
    }
  }
  
  // 🔧 추가: 최신 메시지 동기화
  Future<void> _syncLatestMessages() async {
    try {
      if (_channel != null) {
        final request = {
          'type': 'sync_latest',
          'last_message_time': _lastMessageTime?.toIso8601String(),
          'timestamp': DateTime.now().toIso8601String(),
        };
        _channel!.sink.add(jsonEncode(request));
        log('📡 최신 메시지 동기화 요청 전송');
      }
    } catch (e) {
      log('❌ 최신 메시지 동기화 요청 실패: $e');
    }
  }
  
  Future<bool> connect(String chatRoomId, {String? userId, String? userEmail}) async {
    // 연결 정보 저장
    _currentChatRoomId = chatRoomId;
    _currentUserId = userId;
    _currentUserEmail = userEmail;
    
    return await _performConnection();
  }
  
  // 🔧 추가: 실제 연결 수행
  Future<bool> _performConnection() async {
    if (_isReconnecting) {
      log('🔄 이미 재연결 중...');
      return false;
    }
    
    try {
      _isReconnecting = true;
      _connectionController.add('연결 중...');
      
      // 기존 연결 정리
      await _cleanupConnection();
      
      // WebSocket URL 구성
      final wsUrl = '$_serverUrl$_currentChatRoomId/';
      log('🔌 WebSocket 연결 시도: $wsUrl');
      
      final uri = Uri.parse(wsUrl);
      final queryParams = <String, String>{};
      if (_currentUserId != null) queryParams['user_id'] = _currentUserId!;
      if (_currentUserEmail != null) queryParams['user_email'] = _currentUserEmail!;
      
      final finalUri = uri.replace(queryParameters: queryParams);
      log('🔌 최종 연결 URL: $finalUri');
      
      _channel = WebSocketChannel.connect(finalUri);
      
      // 연결 완료 대기
      await _waitForWebSocketConnection();
      
      // 메시지 리스너 설정
      _setupMessageListener();
      
      // 기존 메시지 히스토리 요청
      await _requestMessageHistory();
      
      // 하트비트 시작
      _startHeartbeat();
      
      // 연결 상태 업데이트
      _isConnected = true;
      _isReconnecting = false;
      _reconnectAttempts = 0;
      _connectionController.add('CONNECTED');
      
      log('✅ WebSocket 연결 성공!');
      return true;
      
    } catch (e) {
      log('❌ WebSocket 연결 실패: $e');
      _isConnected = false;
      _isReconnecting = false;
      _connectionController.add('ERROR: $e');
      
      // 자동 재연결 스케줄
      _scheduleReconnection();
      return false;
    }
  }
  
  // 🔧 추가: 재연결 수행
  Future<void> _performReconnection() async {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      log('❌ 최대 재연결 시도 횟수 초과');
      return;
    }
    
    _reconnectAttempts++;
    log('🔄 재연결 시도 $_reconnectAttempts/$_maxReconnectAttempts');
    
    await _performConnection();
  }
  
  // 🔧 추가: 재연결 스케줄링
  void _scheduleReconnection() {
    _reconnectTimer?.cancel();
    
    if (_reconnectAttempts < _maxReconnectAttempts) {
      // 더 관대한 재연결 지연: 5초, 10초, 15초, 20초, 25초
      final delay = Duration(seconds: _reconnectDelay + (_reconnectAttempts * 5));
      log('⏰ ${delay.inSeconds}초 후 재연결 시도 예정 (시도 ${_reconnectAttempts + 1}/$_maxReconnectAttempts)');
      
      _reconnectTimer = Timer(delay, () {
        _performReconnection();
      });
    } else {
      log('❌ 최대 재연결 시도 횟수 초과. 수동으로 재연결해주세요.');
    }
  }
  
  // 🔧 추가: 연결 정리
  Future<void> _cleanupConnection() async {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    
    if (_channel != null) {
      try {
        await _channel?.sink.close();
      } catch (e) {
        log('⚠️ 기존 WebSocket 정리 실패: $e');
      }
      _channel = null;
    }
  }
  
  // 🔧 추가: 메시지 리스너 설정
  void _setupMessageListener() {
    _channel!.stream.listen(
      (message) {
        log('📡 WebSocket 메시지 수신: $message');
        _lastMessageTime = DateTime.now();
        _handleMessage(message);
      },
      onError: (error) {
        log('❌ WebSocket 스트림 에러: $error');
        _handleError(error);
      },
      onDone: () {
        log('🔚 WebSocket 스트림 완료');
        _handleDisconnect();
      },
    );
    log('✅ 메시지 수신 리스너 설정 완료');
  }
  
  Future<void> _waitForWebSocketConnection() async {
    Completer<void> completer = Completer<void>();
    Timer? timeoutTimer;
    
    // 연결 상태 확인
    void checkConnection() {
      if (_channel != null && _channel!.sink != null) {
        log('✅ WebSocket 연결 상태 정상');
        completer.complete();
        timeoutTimer?.cancel();
      }
    }
    
    // 즉시 확인
    checkConnection();
    
    // 아직 연결되지 않았다면 잠시 대기
    if (!completer.isCompleted) {
      log('⏳ WebSocket 연결 대기 중...');
      await Future.delayed(const Duration(milliseconds: 100));
      checkConnection();
    }
    
    // 타임아웃 설정 (5초)
    timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        log('⏰ WebSocket 연결 타임아웃');
        completer.completeError('WebSocket 연결 타임아웃');
      }
    });
    
    await completer.future;
  }
  
  Future<void> _requestMessageHistory() async {
    try {
      if (_channel != null) {
        log('📚 기존 메시지 히스토리 요청');
        final request = {
          'type': 'request_history',
          'timestamp': DateTime.now().toIso8601String(),
        };
        _channel!.sink.add(jsonEncode(request));
      }
    } catch (e) {
      log('❌ 메시지 히스토리 요청 실패: $e');
    }
  }
  
  Future<void> sendMessage(String content) async {
    if (_channel != null && _isConnected) {
      final message = {
        'type': 'message',
        'content': content,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _channel!.sink.add(jsonEncode(message));
    } else {
      log('❌ WebSocket 연결되지 않음 - 메시지 전송 실패');
      // 연결이 끊어졌다면 재연결 시도
      if (!_isConnected && _currentChatRoomId != null) {
        await _performReconnection();
      }
    }
  }
  
  void _handleMessage(dynamic message) {
    try {
      log('📥 원본 메시지 수신: $message');
      final data = jsonDecode(message);
      log('📊 파싱된 메시지: $data');
      
      if (data['type'] == 'chat_message') {
        log('💬 채팅 메시지 처리: ${data['message']['content']}');
        
        final chatMessage = ChatMessage(
          messageId: data['message']['id'],
          chatRoomId: 'current_room',
          senderId: data['message']['sender_id'] ?? data['message']['sender'],
          senderName: data['message']['sender'],
          content: data['message']['content'],
          messageType: data['message']['message_type'],
          timestamp: DateTime.parse(data['message']['created_at']),
          isRead: false,
          isPinned: data['message']['is_pinned'] ?? false,
        );
        
        _messageController.add(chatMessage);
        log('✅ 채팅 메시지 추가 완료');
        
      } else if (data['type'] == 'admin_message') {
        log('👑 관리자 메시지 처리: $data');
        
        final messageData = data['message'];
        _messageController.add(ChatMessage(
          messageId: messageData['id'] ?? _generateUuid(),
          chatRoomId: 'current_room',
          senderId: messageData['sender_id'] ?? 'admin',
          senderName: messageData['sender'] ?? '관리자',
          content: messageData['content'] ?? '관리자 메시지',
          messageType: 'ADMIN',
          timestamp: messageData['created_at'] != null 
              ? DateTime.parse(messageData['created_at'])
              : DateTime.now(),
          isRead: false,
          isPinned: messageData['is_pinned'] ?? false,
        ));
        log('✅ 관리자 메시지 추가 완료');
        
      } else if (data['type'] == 'announcement') {
        log('📢 공지사항 처리: $data');
        
        final messageData = data['message'];
        _messageController.add(ChatMessage(
          messageId: messageData['id'] ?? _generateUuid(),
          chatRoomId: 'current_room',
          senderId: messageData['sender_id'] ?? 'admin',
          senderName: messageData['sender'] ?? '관리자',
          content: messageData['content'] ?? '공지사항',
          messageType: 'ANNOUNCEMENT',
          timestamp: messageData['created_at'] != null 
              ? DateTime.parse(messageData['created_at'])
              : DateTime.now(),
          isRead: false,
          isPinned: messageData['is_pinned'] ?? false,
        ));
        log('✅ 공지사항 추가 완료');
        
      } else if (data['type'] == 'message_history') {
        log('📚 메시지 히스토리 수신: ${data['messages']?.length ?? 0}개 메시지');
        
        final List<ChatMessage> historyMessages = [];
        
        if (data['messages'] != null) {
          for (final messageData in data['messages']) {
            try {
              final chatMessage = ChatMessage(
                messageId: messageData['id'],
                chatRoomId: 'current_room',
                senderId: messageData['sender_id'] ?? messageData['sender'],
                senderName: messageData['sender'],
                content: messageData['content'],
                messageType: messageData['message_type'],
                timestamp: DateTime.parse(messageData['created_at']),
                isRead: false,
                isPinned: messageData['is_pinned'] ?? false,
              );
              historyMessages.add(chatMessage);
            } catch (e) {
              log('❌ 히스토리 메시지 파싱 실패: $e');
            }
          }
        }
        
        // 배치로 메시지 전송 (빈 배열이어도 전송하여 로딩 상태 해제)
        _messageController.add(ChatMessage(
          messageId: 'history_batch_${_generateUuid()}',
          chatRoomId: 'system',
          senderId: 'system',
          senderName: 'System',
          content: jsonEncode({
            'type': 'MESSAGE_HISTORY_BATCH',
            'messages': historyMessages.map((m) => {
              'id': m.messageId,
              'sender_id': m.senderId,
              'sender': m.senderName,
              'content': m.content,
              'message_type': m.messageType,
              'created_at': m.timestamp.toIso8601String(),
              'is_pinned': m.isPinned,
            }).toList(),
          }),
          messageType: 'MESSAGE_HISTORY_BATCH',
          timestamp: DateTime.now(),
          isRead: false,
        ));
        log('✅ 메시지 히스토리 배치 전송: ${historyMessages.length}개');
        
      } else if (data['type'] == 'sync_latest_response') {
        log('🔄 최신 메시지 동기화 응답: ${data['messages']?.length ?? 0}개 새 메시지');
        
        if (data['messages'] != null) {
          for (final messageData in data['messages']) {
            try {
              final chatMessage = ChatMessage(
                messageId: messageData['id'],
                chatRoomId: 'current_room',
                senderId: messageData['sender_id'] ?? messageData['sender'],
                senderName: messageData['sender'],
                content: messageData['content'],
                messageType: messageData['message_type'],
                timestamp: DateTime.parse(messageData['created_at']),
                isRead: false,
                isPinned: messageData['is_pinned'] ?? false,
              );
              _messageController.add(chatMessage);
            } catch (e) {
              log('❌ 동기화 메시지 파싱 실패: $e');
            }
          }
        }
        
      } else if (data['type'] == 'user_info') {
        log('👤 사용자 정보 수신: $data');
        
        final userInfo = {
          'user_id': data['user_id'],
          'user_name': data['user_name'],
          'display_name': data['display_name'],
          'is_admin': data['is_admin'],
          'connection_suffix': data['connection_suffix'],
        };
        
        _messageController.add(ChatMessage(
          messageId: 'user_info_${_generateUuid()}',
          chatRoomId: 'current_room',
          senderId: 'system',
          senderName: 'System',
          content: jsonEncode(userInfo),
          messageType: 'USER_INFO',
          timestamp: DateTime.now(),
          isRead: false,
          isPinned: false,
        ));
        log('✅ 사용자 정보 메시지 추가 완료');
        
      } else if (data['type'] == 'heartbeat_ack') {
        log('💓 하트비트 응답 수신');
        
      } else {
        log('❓ 알 수 없는 메시지 타입: ${data['type']}');
      }
      
    } catch (e) {
      log('❌ 메시지 파싱 에러: $e');
    }
  }
  
  void _handleError(error) {
    log('❌ WebSocket 에러: $error');
    _isConnected = false;
    _connectionController.add('ERROR: $error');
    
    // 자동 재연결 시도
    _scheduleReconnection();
  }
  
  void _handleDisconnect() {
    log('🔌 WebSocket 연결 해제됨');
    _isConnected = false;
    _connectionController.add('DISCONNECTED');
    _stopHeartbeat();
    
    // 자동 재연결 시도
    _scheduleReconnection();
  }
  
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_channel != null && _isConnected) {
        try {
          _channel!.sink.add(jsonEncode({
            'type': 'heartbeat',
            'timestamp': DateTime.now().toIso8601String(),
          }));
          log('💓 하트비트 전송');
        } catch (e) {
          log('❌ 하트비트 전송 실패: $e');
          _handleDisconnect();
        }
      }
    });
  }
  
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
  
  Future<void> disconnect() async {
    log('🔌 WebSocket 연결 종료 요청');
    
    // 재연결 방지
    _reconnectAttempts = _maxReconnectAttempts;
    
    await _cleanupConnection();
    
    _isConnected = false;
    
    // 컨트롤러가 닫히지 않은 경우에만 이벤트 추가
    if (!_connectionController.isClosed) {
      _connectionController.add('DISCONNECTED');
    }
  }
  
  void dispose() {
    log('🗑️ StompChatService 정리');
    disconnect();
    
    // 컨트롤러들이 아직 닫히지 않은 경우에만 닫기
    if (!_messageController.isClosed) {
      _messageController.close();
    }
    if (!_connectionController.isClosed) {
      _connectionController.close();
    }
  }
  
  // Getter
  bool get isConnected => _isConnected;
  
  // UUID 생성 함수 (간단한 버전)
  String _generateUuid() {
    final random = Random();
    final chars = '0123456789abcdef';
    String uuid = '';
    
    // UUID v4 형태: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
    for (int i = 0; i < 32; i++) {
      if (i == 8 || i == 12 || i == 16 || i == 20) {
        uuid += '-';
      }
      if (i == 12) {
        uuid += '4'; // version 4
      } else if (i == 16) {
        uuid += chars[8 + random.nextInt(4)]; // variant bits
      } else {
        uuid += chars[random.nextInt(16)];
      }
    }
    
    return uuid;
  }
}