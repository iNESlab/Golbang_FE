import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/chat_room.dart';
import '../../models/event.dart';
import '../../utils/reponsive_utils.dart';
import '../../services/stomp_chat_service.dart';
import '../../global/PrivateClient.dart';
import '../../services/chat/image_service.dart';
import '../../services/chat/notification_service.dart';
import '../../services/chat/block_service.dart';
import '../../services/chat_service.dart';
import '../../app/current_route_service.dart';
import 'widgets/message_list.dart';
import 'widgets/reactions.dart';
import 'widgets/bottom_sheet_item.dart';
import 'widgets/report_dialog.dart';
import 'widgets/block_dialog.dart';
import 'dart:convert'; // Added for jsonDecode
import 'dart:developer'; // Added for log function
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../provider/club/club_state_provider.dart';
import 'dart:convert' show base64Url, utf8; // Added for JWT decoding
import 'package:flutter/services.dart'; // Added for Clipboard
import 'package:image_picker/image_picker.dart'; // Added for image picker
import 'dart:io'; // Added for File
import 'package:dio/dio.dart'; // Added for FormData and MultipartFile
import 'package:http_parser/http_parser.dart'; // Added for MediaType


class ClubChatPage extends ConsumerStatefulWidget {
  final int clubId;
  final ChatRoom? chatRoom;

  const ClubChatPage({
    super.key,
    required this.clubId,
    this.chatRoom,
  });

  @override
  ConsumerState<ClubChatPage> createState() => _ClubChatPageState();
}

class _ClubChatPageState extends ConsumerState<ClubChatPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // 🔧 추가: 메시지별 업로드 상태 추적
  Set<String> _uploadingMessages = {}; // 업로드 중인 메시지 ID들

  // 🔧 서비스 인스턴스들
  late final ImageService _imageService;
  late final NotificationService _notificationService;
  late final BlockService _blockService;

  // 🔧 추가: 이미지 업로드 관련 변수 (서비스로 이동 예정)
  XFile? _selectedImage;

  // 🔧 추가: 알림 설정 관련 변수
  bool _isNotificationEnabled = true;
  late final ChatService _chatService;

  // 🔧 수정: 이미지 선택 (ImageService 사용)
  Future<void> _pickImage(ImageSource source) async {
    await _imageService.pickImage(
      source,
      onImageSelected: (XFile? image) {
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        // 선택된 이미지를 미리보기 화면에 표시
        _showImagePreviewDialog();
      }
      },
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );
  }

  // 🔧 수정: 이미지 미리보기 후 전송 방식으로 변경
  Future<void> _sendImageMessage() async {
    if (_selectedImage == null) return;

    // 임시 메시지 ID 생성
    final tempMessageId = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      // 1. 업로드 상태로 설정
      setState(() {
        _uploadingMessages.add(tempMessageId);
      });

      // 2. 임시 메시지 생성 (업로드 중 표시용)
      final tempImageMessage = ChatMessage(
        messageId: tempMessageId,
        chatRoomId: widget.clubId.toString(),
        senderId: _currentUserId,
        senderName: _currentUserName,
        content: '{"type":"image","status":"uploading","filename":"${_selectedImage!.name}"}',
        messageType: 'IMAGE',
        timestamp: DateTime.now(),
        isRead: false,
      );

      // UI에 임시 메시지 추가
      _messages.add(tempImageMessage);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      setState(() {});
      _scrollToBottom(animated: true);

      // 3. S3에 이미지 업로드 (ImageService 사용)
      final uploadResult = await _imageService.uploadImageToServer(_selectedImage!);
      if (uploadResult == null) {
        // 업로드 실패 시 임시 메시지 제거
        setState(() {
          _messages.removeWhere((m) => m.messageId == tempMessageId);
          _uploadingMessages.remove(tempMessageId);
        });
        return;
      }

      // 4. 업로드 성공 시 최종 메시지 데이터 생성
      final imageData = {
        'type': 'image',
        'image_url': uploadResult['image_url'],
        'thumbnail_url': uploadResult['thumbnail_url'],
        'filename': uploadResult['filename'],
        'size': uploadResult['size'],
        'content_type': uploadResult['content_type']
      };

      // 임시 메시지를 실제 데이터로 업데이트
      final messageIndex = _messages.indexWhere((m) => m.messageId == tempMessageId);
      if (messageIndex != -1) {
        _messages[messageIndex] = ChatMessage(
          messageId: tempMessageId, // 실제 메시지가 올 때까지 임시 ID 사용
          chatRoomId: widget.clubId.toString(),
          senderId: _currentUserId,
          senderName: _currentUserName,
          content: jsonEncode(imageData),
          messageType: 'IMAGE',
          timestamp: DateTime.now(),
          isRead: false,
        );
        setState(() {});
      }

      // 서버로 전송 (일반 chat_message로)
      if (_isConnected) {
        _stompService.sendMessage(jsonEncode({
          'type': 'chat_message',
          'content': jsonEncode(imageData),
          'message_type': 'IMAGE',
        }));
      }

      // 업로드 상태 제거
      setState(() {
        _uploadingMessages.remove(tempMessageId);
        _selectedImage = null;
      });

    } catch (e) {
      log('❌ 이미지 메시지 전송 실패: $e');

      // 실패 시 임시 메시지 제거
      setState(() {
        _messages.removeWhere((m) => m.messageId == tempMessageId);
        _uploadingMessages.remove(tempMessageId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 전송에 실패했습니다: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 🔧 추가: 서버에 이미지 업로드
  Future<Map<String, dynamic>?> _uploadImageToServer(XFile imageFile) async {
    try {
      final privateClient = PrivateClient();

      // MultipartFile 생성
      final bytes = await imageFile.readAsBytes();
      final multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: imageFile.name,
        contentType: MediaType.parse(imageFile.mimeType ?? 'image/jpeg'),
      );

      final formData = FormData.fromMap({
        'image': multipartFile,
      });

      final response = await privateClient.dio.post(
        '/api/v1/chat/upload-image/',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true) {
          log('✅ 이미지 업로드 성공: ${data['image_url']}');
          return {
            'image_url': data['image_url'],
            'thumbnail_url': data['thumbnail_url'],
            'filename': data['filename'],
            'size': data['size'],
            'content_type': data['content_type']
          };
        }
      }

      log('❌ 이미지 업로드 실패: ${response.statusCode}');
      return null;

    } catch (e) {
      log('❌ 이미지 업로드 오류: $e');
      return null;
    }
  }

  // 🔧 추가: 이미지 선택 다이얼로그 표시 (ImageService 사용)
  void _showImagePickerDialog() {
    _imageService.showImagePickerDialog(
      context: context,
      onSourceSelected: (ImageSource source) {
        _pickImage(source);
      },
    );
  }

  // 🔧 추가: 이미지 미리보기 다이얼로그 (ImageService 사용)
  void _showImagePreviewDialog() {
    if (_selectedImage == null) return;

    _imageService.showImagePreviewDialog(
      context: context,
      imageFile: _selectedImage!,
      onSend: () async {
        await _sendImageMessage();
      },
      onCancel: () {
                        setState(() {
          _selectedImage = null;
        });
      },
      screenHeight: screenHeight,
      getFontSizeMedium: () => fontSizeMedium,
      getFontSizeSmall: () => fontSizeSmall,
    );
  }

  
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
  
  // 🔧 차단된 사용자 관리 (BlockService로 이동 예정)
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

    // 🔧 서비스 초기화
    _imageService = ImageService();
    _notificationService = NotificationService();
    _blockService = BlockService();
    _chatService = ChatService(PrivateClient());

    _stompService = StompChatService();
    
    // 🔧 추가: 현재 라우트 업데이트 (채팅방 진입)
    final chatRoute = '/app/clubs/${widget.clubId}/chat';
    CurrentRouteService.updateRoute(chatRoute);
    log('🔧 채팅방 진입 - 라우트 업데이트: $chatRoute');
    log('🔧 현재 라우트 확인: ${CurrentRouteService.currentRoute}');
    log('🔧 현재 채팅방 ID: ${CurrentRouteService.currentChatRoomId}');
    log('🔧 현재 채팅방 타입: ${CurrentRouteService.currentChatRoomType}');
    
    // 🔧 추가: Club에서 관리자 정보 설정
    _isAdmin = false; // TODO: 실제 관리자 여부 확인 필요
    log('🔧 initState에서 _isAdmin 설정: $_isAdmin');
    
  // 🔧 추가: 차단된 사용자 목록 로드 (BlockService 사용)
    log('🔧 initState에서 차단된 사용자 목록 로드 시작');
  _blockService.loadBlockedUsers();
    
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

    // 🔧 추가: 로컬 알림 초기화 (NotificationService 사용)
    _initializeNotifications();

    // 🔧 추가: 알림 설정 상태 로드
    _loadNotificationStatus();

    // 🔧 추가: 앱 라이프사이클 옵저버 등록
    WidgetsBinding.instance.addObserver(this);

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
      // 🔧 추가: 클럽 정보 로드
      _loadClubInfo();
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
        'club_${widget.clubId}',
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
  void _onMessageReceived(ChatMessage message, {bool isFromStomp = false}) {
    // 메시지 타입별로 처리 분리
    if (message.messageType == 'USER_INFO') {
      _handleUserInfoMessage(message);
      return;
    }

    // 🔧 추가: 새로운 메시지 타입들 처리
    if (message.messageType == 'MESSAGE_HISTORY_BATCH' || message.messageType == 'message_history') {
      _handleHistoryBatchMessage(message);
      return;
    }

    // 🔧 추가: admin_message 타입 직접 처리
    if (message.content.startsWith('{"type":"admin_message"')) {
      _handleDirectAdminMessage(message);
      return;
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
      _handleSystemMessage(message);
      return;
    }

    // 🔧 추가: 차단된 사용자 메시지 확인 (BlockService 사용)
    if (_blockService.isUserBlocked(message.senderId)) {
      log('🚫 차단된 사용자의 실시간 메시지 수신: ${message.senderName} (${message.senderId})');
    }

    // --- 핵심 로직 시작 ---
    _handleMessageCoreLogic(message, isFromStomp);
    // --- 핵심 로직 끝 ---
    setState(() {}); // 🔧 최적화: setState() 최소화

    // 스크롤을 맨 아래로 이동 (새 메시지가 추가될 때는 애니메이션 없이 바로 이동)
    _scrollToBottom(animated: false);

    // 🔧 비활성화: WebSocket 로컬 알림 (FCM 알림으로 대체)
    // if (isFromStomp && message.senderId.toString() != _currentUserId) {
    //   _showChatNotification(message);
    // }
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

  // 🔧 추가: USER_INFO 메시지 처리
  void _handleUserInfoMessage(ChatMessage message) {
      log('📨 USER_INFO 메시지 수신: ${message.content}');
      try {
        final userInfo = jsonDecode(message.content);
        log('📨 파싱된 사용자 정보: $userInfo');
        _onUserInfoReceived(userInfo);
      } catch (e) {
        log('❌ 사용자 정보 파싱 실패: $e');
      }
    }
    
  // 🔧 추가: MESSAGE_HISTORY_BATCH 메시지 처리
  void _handleHistoryBatchMessage(ChatMessage message) {
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
              } else if (specialData['type'] == 'image_message') {
                // 🔧 추가: 히스토리에서 이미지 메시지 처리
                final imageData = specialData['data'];
                content = jsonEncode(imageData); // image 데이터만 추출
                messageType = 'IMAGE';
                log('🖼️ 히스토리에서 이미지 메시지 변환: ${imageData['filename']}');
              } else if (specialData['type'] == 'chat_message') {
                // 🔧 추가: 히스토리에서 중첩된 chat_message 처리
                final innerContent = specialData['content'];
                if (innerContent != null) {
                  try {
                    final innerData = jsonDecode(innerContent);
                    if (innerData['type'] == 'image') {
                      content = innerContent; // 이미지 데이터 그대로 사용
                      messageType = 'IMAGE';
                      log('🖼️ 히스토리에서 중첩 이미지 메시지 변환: ${innerData['filename']}');
                    }
                  } catch (e) {
                    log('❌ 중첩 JSON 파싱 실패: $e');
                  }
                }
              }
            } catch (e) {
              log('❌ 특수 메시지 파싱 실패: $e');
            }
          }
          
          return ChatMessage(
            messageId: msgData['id'],
            chatRoomId: 'current_room',
            senderId: msgData['sender_id'],
            senderUniqueId: msgData['sender_unique_id']?.toString(),
            senderName: msgData['sender_name'] ?? msgData['sender'],
            senderProfileImage: msgData['sender_profile_image'],
            content: content,
            messageType: messageType,
            timestamp: DateTime.parse(msgData['created_at']),
            isRead: false,
          );
        }).whereType<ChatMessage>().toList();
        _onMessageHistoryReceived(historyMessages);
        
        // 🔧 추가: 히스토리 로드 후 차단된 사용자 메시지 확인
        _checkBlockedMessagesAfterHistoryLoad();
      } catch (e) {
        log('❌ 히스토리 배치 파싱 실패: $e');
    }
  }

  // 🔧 추가: 메시지 핵심 로직 처리 (에코/일반 메시지)
  void _handleMessageCoreLogic(ChatMessage message, bool isFromStomp) {
    // 1. 내가 보낸 메시지가 서버로부터 돌아온 경우 (Echo 처리)
    log('🔍 내가 보낸 메시지가 서버로부터 돌아온 경우: ${message.senderId} == ${_currentUserId}');
    log('🔍 타입 비교: ${message.senderId.runtimeType} vs ${_currentUserId.runtimeType}');
    log('🔍 문자열 비교: "${message.senderId.toString()}" == "${_currentUserId}"');
    log('🔍 비교 결과: ${message.senderId.toString() == _currentUserId}');
    if (isFromStomp && message.senderId.toString() == _currentUserId) {
      // 🔧 수정: 업로드 중인 메시지를 우선 찾고, 없으면 기존 로직 사용
      int index = -1;

      // 1. 업로드 중인 메시지 우선 찾기
      if (_uploadingMessages.isNotEmpty) {
        index = _messages.lastIndexWhere((m) =>
            _uploadingMessages.contains(m.messageId) && m.senderId.toString() == _currentUserId);
      }

      // 2. 업로드 중인 메시지가 없으면 기존 로직 (임시 메시지 찾기)
      if (index == -1) {
        index = _messages.lastIndexWhere((m) =>
            m.senderId.toString() == _currentUserId && m.messageId.length < 36);
      }

      if (index != -1) {
        // 🔧 수정: 에코 메시지도 중첩 JSON 언래핑 처리
        ChatMessage finalMessage = message;
        if (message.content.startsWith('{"type":"chat_message"')) {
          try {
            final wrapperData = jsonDecode(message.content);
            if (wrapperData['type'] == 'chat_message') {
              finalMessage = ChatMessage(
                messageId: message.messageId,
                chatRoomId: message.chatRoomId,
                senderId: message.senderId,
                senderUniqueId: message.senderUniqueId,
                senderName: message.senderName,
                senderProfileImage: message.senderProfileImage, // 🔧 추가: 프로필 이미지 보존
                content: wrapperData['content'],
                messageType: wrapperData['message_type'] ?? message.messageType,
                timestamp: message.timestamp,
                isRead: message.isRead,
                isPinned: message.isPinned,
              );
              log('🔄 에코 메시지 중첩 JSON 언래핑: ${finalMessage.messageType}');
            }
          } catch (e) {
            log('❌ 에코 메시지 중첩 JSON 언래핑 실패: $e');
          }
        }

        // 임시 메시지를 서버가 보내준 진짜 메시지로 교체!
        log('🔄 에코 메시지 수신! 임시 메시지를 서버 버전으로 교체합니다: ${finalMessage.content}');
        _messages[index] = finalMessage;

        // 🔧 추가: 업로드 상태 제거
        if (_uploadingMessages.contains(_messages[index].messageId)) {
          _uploadingMessages.remove(_messages[index].messageId);
        }
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
  }

  // 🔧 추가: SYSTEM 메시지 처리
  void _handleSystemMessage(ChatMessage message) {
    log('🔧 시스템 메시지 수신: ${message.content}');
    _messages.add(message);
    _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    setState(() {}); // 🔧 최적화: setState() 최소화
    _scrollToBottom();
  }

  // 🔧 추가: 직접 수신된 admin_message 처리
  void _handleDirectAdminMessage(ChatMessage message) {
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
            }
          } catch (e) {
      log('❌ 관리자 메시지 파싱 실패: $e');
    }
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
      chatRoomId: widget.clubId.toString(),
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
      log('🔔 FCM 알림 전송 예상: 서버에서 다른 사용자들에게 알림 전송');
      _stompService.sendMessage(message.content);
    } else {
      log('❌ STOMP 연결 없음 - 메시지 전송 불가');
    }

    // 스크롤 로직 개선 (부드럽지만 빠른 애니메이션)
    _scrollToBottom(animated: true);
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
    // 🔧 수정: dispose 전에 모든 메시지 읽음 처리 API 호출
    _markAllMessagesAsReadSync();
    
    // 🔧 추가: 채팅방 나가기 - 라우트 초기화
    log('🔧 채팅방 나가기 전 현재 상태:');
    log('🔧 현재 라우트: ${CurrentRouteService.currentRoute}');
    log('🔧 현재 채팅방 ID: ${CurrentRouteService.currentChatRoomId}');
    log('🔧 현재 채팅방 타입: ${CurrentRouteService.currentChatRoomType}');
    CurrentRouteService.updateRoute(null);
    log('🔧 채팅방 나가기 - 라우트 초기화 완료');
    
    // 안전한 순서로 정리
    _messageController.dispose();
    _scrollController.dispose();
    _pinnedMessageAnimationController.dispose();

    // 🔧 추가: 앱 라이프사이클 옵저버 제거
    WidgetsBinding.instance.removeObserver(this);

    // 서비스들을 안전하게 정리
    try {
      _stompService.dispose();
    } catch (e) {
      log('StompService dispose 오류: $e');
    }

    super.dispose();
  }

  // 🔧 추가: 채팅방 나갈 때 모든 메시지 읽음 처리 (동기적)
  void _markAllMessagesAsReadSync() {
    try {
      log('🔄 채팅방 나가기: 모든 메시지 읽음 처리');
      
      // mounted 체크
      if (!mounted) {
        log('⚠️ 위젯이 이미 dispose됨: 읽음 처리 스킵');
        return;
      }
      
      // 동기적으로 API 호출 (fire-and-forget)
      _markAllMessagesAsRead().catchError((e) {
        log('❌ 읽음 처리 API 호출 실패: $e');
      });
      
      log('✅ 채팅방 나가기: 읽음 처리 API 호출 완료');
      
    } catch (e) {
      log('❌ 읽음 처리 실패: $e');
    }
  }
  
  // 🔧 추가: 채팅방 나갈 때 unread count 업데이트 (동기적)
  void _updateUnreadCountOnExitSync() {
    try {
      log('🔄 채팅방 나가기: unread count 동기적 업데이트');
      
      // mounted 체크
      if (!mounted) {
        log('⚠️ 위젯이 이미 dispose됨: unread count 업데이트 스킵');
        return;
      }
      
      // 동기적으로 clubStateProvider만 업데이트 (API 호출 없이)
      ref.read(clubStateProvider.notifier).fetchClubs();
      log('✅ 채팅방 나가기: unread count 동기적 업데이트 완료');
      
    } catch (e) {
      log('❌ unread count 동기적 업데이트 실패: $e');
    }
  }
  
  // 🔧 추가: 채팅방 나갈 때 unread count 업데이트 (비동기적 - 기존)
  void _updateUnreadCountOnExit() {
    try {
      log('🔄 채팅방 나가기: unread count 즉시 업데이트');
      
      // 🔧 수정: mounted 체크 후 즉시 unread count 업데이트
      if (mounted) {
        _refreshUnreadCountImmediately();
      } else {
        log('⚠️ 위젯이 이미 dispose됨: unread count 업데이트 스킵');
      }
      
    } catch (e) {
      log('❌ unread count 업데이트 실패: $e');
    }
  }
  
  // 🔧 추가: 즉시 unread count 업데이트하는 메서드
  Future<void> _refreshUnreadCountImmediately() async {
    try {
      // mounted 체크 추가
      if (!mounted) {
        log('⚠️ 위젯이 이미 dispose됨: unread count 업데이트 스킵');
        return;
      }
      
      // 1. 먼저 모든 메시지를 읽음 처리
      await _markAllMessagesAsRead();
      
      // mounted 체크 추가
      if (!mounted) {
        log('⚠️ 위젯이 이미 dispose됨: clubStateProvider 업데이트 스킵');
        return;
      }
      
      // 2. 그 다음 clubStateProvider를 통해 unread count 업데이트
      await ref.read(clubStateProvider.notifier).fetchClubs();
      log('✅ 채팅방 나가기: unread count 즉시 업데이트 완료');
    } catch (e) {
      log('❌ 즉시 unread count 업데이트 실패: $e');
    }
  }

  // 🔧 추가: 앱 라이프사이클 콜백
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // 앱이 포그라운드로 돌아옴
        _notificationService.setForegroundState(true);
        log('📱 앱 포그라운드 상태로 변경');
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // 앱이 백그라운드로 감
        _notificationService.setForegroundState(false);
        log('📱 앱 백그라운드 상태로 변경');
        break;
      case AppLifecycleState.hidden:
        // iOS 17+ 에서 추가됨
        _notificationService.setForegroundState(false);
        log('📱 앱 숨김 상태로 변경');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    orientation = MediaQuery.of(context).orientation;
    fontSizeLarge = ResponsiveUtils.getLargeFontSize(screenWidth, orientation);
    fontSizeMedium = ResponsiveUtils.getMediumFontSize(screenWidth, orientation);
    fontSizeSmall = ResponsiveUtils.getSmallFontSize(screenWidth, orientation);
    
    // 🔧 추가: build 메서드에서도 라우트 업데이트 (MainScaffold 덮어쓰기 방지)
    final chatRoute = '/app/clubs/${widget.clubId}/chat';
    CurrentRouteService.updateRoute(chatRoute);

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        log('🔍 PopScope onPopInvoked: didPop=$didPop');
        if (didPop) {
          log('🔄 뒤로가기 시작: 모든 메시지 읽음 처리 API 호출');
          // 뒤로가기 시 모든 메시지 읽음 처리
          await _markAllMessagesAsRead();
          log('🔄 뒤로가기: 모든 메시지 읽음 처리 완료');
          
          // 🔧 추가: clubStateProvider 업데이트
          log('🔄 뒤로가기: clubStateProvider 업데이트 시작');
          await ref.read(clubStateProvider.notifier).fetchClubs();
          log('🔄 뒤로가기: clubStateProvider 업데이트 완료');
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _clubName,
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
          // 🔧 단순화: 알림 아이콘만
          IconButton(
            icon: Icon(
              _isNotificationEnabled ? Icons.notifications : Icons.notifications_off,
              color: _isNotificationEnabled ? Colors.white : Colors.white70,
            ),
            onPressed: _toggleNotification,
            tooltip: _isNotificationEnabled ? '알림 끄기' : '알림 켜기',
          ),
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
                      _getPinnedMessageDisplayText(_pinnedMessage!),
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
                  // 🔧 추가: 이미지 업로드 버튼
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.image, color: Colors.grey),
                      onPressed: _showImagePickerDialog,
                      tooltip: '이미지 첨부',
                    ),
                  ),
                  const SizedBox(width: 8),
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
      )    );
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

  
  
  // 🔧 추가: 반응 표시 위젯 (Reactions 위젯으로 분리)
  Widget _buildReactions(String messageId) {
    final reactions = _messageReactions[messageId] ?? {};
    return Reactions(
      reactions: reactions,
      messageId: messageId,
      onAddReaction: (messageId, reaction) => _addReaction(messageId, reaction),
    );
  }

  // 🔧 수정: 이미지 확대 및 메뉴 화면으로 이동
  void _showImagePreview(String data, String filename, {bool isUrl = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(filename, style: const TextStyle(fontSize: 16)),
            actions: [
              // 저장 버튼
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () async {
                  try {
                    // TODO: 이미지 저장 기능 구현
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('이미지 저장 기능은 곧 추가됩니다')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('저장 실패: $e')),
                    );
                  }
                },
              ),
              // 공유 버튼
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  // TODO: 이미지 공유 기능 구현
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('공유 기능은 곧 추가됩니다')),
                  );
                },
              ),
            ],
          ),
          body: Center(
            child: isUrl
                ? InteractiveViewer(
                    child: Image.network(
                      data,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const CircularProgressIndicator();
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.white, size: 64),
                            SizedBox(height: 16),
                            Text(
                              '이미지를 불러올 수 없습니다',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                : InteractiveViewer(
                    child: Image.memory(
                      base64Decode(data),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image, color: Colors.white, size: 64),
                            SizedBox(height: 16),
                            Text(
                              '이미지를 불러올 수 없습니다',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // 🔧 추가: 로컬 알림 초기화 (NotificationService 사용)
  Future<void> _initializeNotifications() async {
    await _notificationService.initializeNotifications();
  }

  // 🔧 추가: 채팅 알림 표시 (NotificationService 사용)
  Future<void> _showChatNotification(ChatMessage message) async {
    await _notificationService.showChatNotification(
      messageId: message.messageId,
      senderName: message.senderName,
      content: message.content,
      senderId: message.senderId,
      currentUserId: _currentUserId,
      messageType: message.messageType ?? '',
      chatRoomId: widget.clubId.toString(),
      clubId: widget.clubId.toString(),
      chatRoomType: 'CLUB',
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
            
            // // 🔧 추가: 개발/테스트용 전체 차단 해제
            // _buildBottomSheetItem(
            //   icon: Icons.delete_forever,
            //   title: '모든 차단 해제 (개발용)',
            //   color: Colors.red,
            //   onTap: () {
            //     Navigator.pop(context);
            //     _clearAllBlockedUsers();
            //   },
            // ),
            
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
    return BottomSheetItem(
      icon: icon,
      title: title,
      color: color,
      fontSizeMedium: fontSizeMedium,
      onTap: onTap,
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
            Text('클럽 ID: ${widget.clubId}', style: TextStyle(fontSize: fontSizeMedium)),
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
  
  
  // 🔧 추가: 클럽 정보
  int _clubMemberCount = 0;
  String _clubName = '클럽';
  
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
                        child: _buildPinnedMessageContent(_pinnedMessage!),
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
  
  Future<void> _loadClubInfo() async {
    try {
      if (widget.clubId != null) {
        final privateClient = PrivateClient();
        final response = await privateClient.get('/api/v1/clubs/${widget.clubId}/');
        
        log('🔍 클럽 API 응답: ${response.statusCode}');
        log('🔍 클럽 API 데이터: ${response.data}');
        
        if (response.statusCode == 200) {
          final responseData = response.data;
          if (responseData is Map && responseData.containsKey('data')) {
            final data = responseData['data'];
            
            // 클럽 이름 로딩
            if (data is Map && data.containsKey('name')) {
              setState(() {
                _clubName = data['name'] ?? '클럽';
              });
              log('✅ 클럽 이름 로딩 성공: $_clubName');
            }
            
            // 멤버 수 로딩
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
                _clubMemberCount = 0;
              });
            }
          } else {
            log('❌ API 응답에 data 필드가 없음');
            log('❌ 응답 구조: ${responseData.keys.toList()}');
            setState(() {
              _clubMemberCount = 0;
            });
          }
        }
      }
    } catch (e) {
      log('❌ 클럽 정보 로딩 오류: $e');
      // 오류 시 기본값 사용
      setState(() {
        _clubMemberCount = 0;
        _clubName = '클럽';
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
        if (widget.clubId != null) {
          try {
            final privateClient = PrivateClient();
            final clubResponse = await privateClient.get('/api/v1/clubs/${widget.clubId}/');
            if (clubResponse.statusCode == 200) {
              final clubData = clubResponse.data;
              if (clubData is Map && clubData.containsKey('data')) {
                final clubInfo = clubData['data'];
                // 클럽 ID를 그대로 사용 (백엔드에서 클럽 ID로 채팅방을 찾음)
                chatRoomId = widget.clubId.toString();
                log('🔍 chatRoomId (from club ID): $chatRoomId');
                log('🔍 widget.clubId: ${widget.clubId}');
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
  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            0.0, // reverse: true일 때 0이 맨 아래
            duration: const Duration(milliseconds: 150), // 더 빠른 애니메이션
            curve: Curves.linear, // 선형 커브로 더 자연스러움
          );
        } else {
          _scrollController.jumpTo(0.0); // 애니메이션 없이 즉시 이동
        }
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
                 // 🔧 수정: 차단된 사용자인 경우 차단 해제 옵션 표시
                   const Divider(),
                 if (_blockService.blockedUsers.contains(message.senderId)) ...[
                   ListTile(
                     leading: const Icon(Icons.block, color: Colors.green),
                     title: const Text('사용자 차단 해제'),
                     onTap: () {
                       Navigator.pop(context);
                       _showUnblockDialog(message);
                     },
                   ),
                 ] else ...[
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

  // 🔧 추가: 고정된 메시지 표시 텍스트 생성
  String _getPinnedMessageDisplayText(ChatMessage message) {
    try {
      // JSON 파싱 시도 (이미지 메시지인 경우)
      final messageData = jsonDecode(message.content);
      if (messageData['type'] == 'image') {
        return "사진이 고정되었습니다";
      }
    } catch (e) {
      // JSON이 아닌 경우 일반 텍스트로 처리
    }
    
    // 일반 텍스트 메시지인 경우
    return message.content;
  }

  // 🔧 추가: 고정된 메시지 내용 위젯 생성
  Widget _buildPinnedMessageContent(ChatMessage message) {
    try {
      // JSON 파싱 시도 (이미지 메시지인 경우)
      final messageData = jsonDecode(message.content);
      if (messageData['type'] == 'image') {
        final imageUrl = messageData['image_url'] as String?;
        final thumbnailUrl = messageData['thumbnail_url'] as String?;
        final displayUrl = thumbnailUrl ?? imageUrl;
        
        if (displayUrl != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "사진이 고정되었습니다",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  // 이미지 미리보기
                  _showImagePreview(displayUrl, messageData['filename'] ?? 'image.jpg');
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    displayUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 48, color: Colors.grey.shade400),
                              SizedBox(height: 8),
                              Text(
                                '이미지를 불러올 수 없습니다',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }
      }
    } catch (e) {
      // JSON이 아닌 경우 일반 텍스트로 처리
    }
    
    // 일반 텍스트 메시지인 경우
    return Text(
      message.content,
      style: TextStyle(
        fontSize: 16,
        color: Colors.black87,
        height: 1.5,
      ),
    );
  }

  // 🔧 추가: 모든 메시지 읽음 상태 업데이트
  Future<void> _markAllMessagesAsRead() async {
    try {
      log('🔍 _markAllMessagesAsRead 시작: chat_room_id=${widget.clubId}');
      final privateClient = PrivateClient();
      final response = await privateClient.dio.post(
        '/api/v1/chat/mark-all-read/',
        data: {
          'chat_room_id': widget.clubId.toString(),
        },
      );
      
      log('🔍 _markAllMessagesAsRead 응답: statusCode=${response.statusCode}');
      if (response.statusCode == 200) {
        log('✅ 모든 메시지 읽음 상태 업데이트 완료');
        // 🔧 수정: setState 제거 - API 호출만 하고 UI 업데이트는 하지 않음
        // dispose 시점에서는 UI 업데이트가 불필요하고 오류를 발생시킴
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
    final startTime = DateTime.now(); // TODO: 실제 시작 시간 로드
    final endTime = DateTime.now().add(const Duration(hours: 1)); // TODO: 실제 종료 시간 로드
    
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

  // 🔧 추가: 신고 다이얼로그 (ReportDialog 위젯 사용)
  void _showReportDialog(ChatMessage message) {
    showReportDialog(
      context: context,
      userName: message.senderName,
      fontSizeLarge: fontSizeLarge,
      fontSizeMedium: fontSizeMedium,
      fontSizeSmall: fontSizeSmall,
      onSubmit: (String reason, String detail) {
        _submitReport(message, reason, detail);
      },
    );
  }

  // 🔧 추가: 신고 제출 (BlockService 사용)
  Future<void> _submitReport(ChatMessage message, String reason, String detail) async {
    final success = await _blockService.submitReport(
      messageId: message.messageId,
      reason: reason,
      detail: detail,
    );

    if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('신고가 접수되었습니다. 검토 후 조치하겠습니다.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('신고 접수 중 오류가 발생했습니다'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // 🔧 추가: 사용자 차단 다이얼로그 (BlockDialog 위젯 사용)
  void _showBlockUserDialog(ChatMessage message) {
    showBlockDialog(
      context: context,
      userName: message.senderName,
      fontSizeLarge: fontSizeLarge,
      fontSizeMedium: fontSizeMedium,
      fontSizeSmall: fontSizeSmall,
      onBlock: () => _blockUser(message),
    );
  }

  // 🔧 추가: 차단된 메시지 토글 (BlockService 사용)
  void _toggleBlockedMessage(ChatMessage message) {
    _blockService.toggleBlockedMessage(message.messageId);
    setState(() {});
  }


  // 🔧 추가: 히스토리 로드 후 차단된 메시지 확인 (BlockService 사용)
  void _checkBlockedMessagesAfterHistoryLoad() {
    if (_blockService.blockedUsers.isEmpty) return;
    
    log('🔧 히스토리 로드 후 차단된 메시지 확인 시작...');
    bool hasBlockedMessages = false;
    
    for (var message in _messages) {
      if (_blockService.isUserBlocked(message.senderId)) {
        log('🚫 차단된 사용자의 메시지 발견: ${message.senderName} (${message.senderId}) - ${message.content.substring(0, 20)}...');
        hasBlockedMessages = true;
      }
    }
    
    if (hasBlockedMessages) {
      log('🔧 차단된 메시지가 있어서 UI 새로고침 실행');
      setState(() {}); // UI 새로고침으로 차단된 메시지 표시
    }
  }

  // 🔧 추가: 서버와 로컬 모든 차단 해제 (개발/테스트용) (BlockService 사용)
  Future<void> _clearAllBlockedUsers() async {
    final success = await _blockService.clearAllBlockedUsers();

    if (success) {
        setState(() {
        // BlockService에서 이미 cleared되었으므로 UI만 업데이트
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('모든 차단이 해제되었습니다.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('차단 해제 중 오류가 발생했습니다'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }





  // 🔧 추가: 사용자 차단 (BlockService 사용)
  Future<void> _blockUser(ChatMessage message) async {
    final success = await _blockService.blockUser(
      blockedUserId: message.senderId,
      reason: '사용자 요청에 의한 차단',
    );

    if (success) {
      // UI 새로고침 및 차단된 메시지를 보기 모드에서 제거
        setState(() {
        _blockService.showBlockedMessages.removeWhere((messageId) {
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
    } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${message.senderName}님은 이미 차단된 사용자입니다.'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
    }
  }



  // 🔧 최적화: 메시지 리스트 빌더 (MessageList 위젯으로 분리)
  Widget _buildMessageList() {
    return MessageList(
      messages: _messages,
      currentUserId: _currentUserId,
      blockService: _blockService,
      uploadingMessages: _uploadingMessages,
      scrollController: _scrollController,
      screenWidth: screenWidth,
      fontSizeMedium: fontSizeMedium,
      fontSizeSmall: fontSizeSmall,
      onToggleBlockedMessage: _toggleBlockedMessage,
      onShowUnblockDialog: _showUnblockDialog,
      onImagePreview: _showImagePreview,
      onLongPress: _showMessageMenu,
    );
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

  // 🔧 추가: 사용자 차단 해제 (BlockService 사용)
  Future<void> _unblockUser(ChatMessage message) async {
    final success = await _blockService.unblockUser(message.senderId);

    if (success) {
      // UI 새로고침 및 해당 사용자의 메시지를 보기 모드에서 제거
        setState(() {
        _blockService.showBlockedMessages.removeWhere((messageId) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('차단 해제 중 오류가 발생했습니다'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // 🔧 추가: 알림 설정 상태 로드
  Future<void> _loadNotificationStatus() async {
    try {
      // 클럽 ID로 직접 알림 설정 조회
      final clubId = widget.clubId;
      final isEnabled = await _chatService.getChatRoomNotificationStatus(clubId.toString());
      
      if (mounted) {
        setState(() {
          _isNotificationEnabled = isEnabled;
        });
        log('🔔 알림 설정 로드: $_isNotificationEnabled (clubId: $clubId)');
      }
    } catch (e) {
      log('❌ 알림 설정 로드 실패: $e');
    }
  }

  // 🔧 추가: 알림 설정 토글
  Future<void> _toggleNotification() async {
    try {
      // 클럽 ID로 직접 알림 설정 토글
      final clubId = widget.clubId;
      final newStatus = await _chatService.toggleChatRoomNotification(clubId.toString());
      
      if (mounted) {
        setState(() {
          _isNotificationEnabled = newStatus;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isNotificationEnabled ? '🔔 알림이 켜졌습니다' : '🔕 알림이 꺼졌습니다'
            ),
            backgroundColor: _isNotificationEnabled ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        
        log('🔔 알림 설정 변경: $_isNotificationEnabled (clubId: $clubId)');
      }
    } catch (e) {
      log('❌ 알림 설정 변경 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('알림 설정 변경 중 오류가 발생했습니다'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
}


