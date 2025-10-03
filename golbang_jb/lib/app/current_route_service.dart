import 'dart:developer';
import 'package:go_router/go_router.dart';

/// 현재 라우트를 추적하는 서비스
class CurrentRouteService {
  static String? _currentRoute;
  static String? _currentChatRoomId;
  static String? _currentChatRoomType;
  
  /// 현재 라우트 업데이트
  static void updateRoute(String? route) {
    _currentRoute = route;
    _currentChatRoomId = _extractChatRoomId(route);
    _currentChatRoomType = _extractChatRoomType(route);
    log('현재 라우트 업데이트: $route, 채팅방 ID: $_currentChatRoomId, 타입: $_currentChatRoomType');
  }
  
  /// 현재 채팅방 ID 추출
  static String? _extractChatRoomId(String? route) {
    if (route == null) return null;
    
    // 채팅방 라우트 패턴들
    final chatPatterns = [
      RegExp(r'/app/events/(\d+)/chat'),  // 이벤트 채팅방
      RegExp(r'/app/clubs/(\d+)/chat'),  // 클럽 채팅방
    ];
    
    for (final pattern in chatPatterns) {
      final match = pattern.firstMatch(route);
      if (match != null) {
        return match.group(1);
      }
    }
    
    return null;
  }
  
  /// 현재 채팅방 타입 추출
  static String? _extractChatRoomType(String? route) {
    if (route == null) return null;
    
    if (route.contains('/app/events/') && route.contains('/chat')) {
      return 'EVENT';
    } else if (route.contains('/app/clubs/') && route.contains('/chat')) {
      return 'CLUB';
    }
    
    return null;
  }
  
  /// 현재 채팅방을 보고 있는지 확인
  static bool isViewingChatRoom(String? chatRoomId) {
    if (chatRoomId == null || _currentChatRoomId == null) return false;
    return _currentChatRoomId == chatRoomId;
  }
  
  /// 현재 채팅방을 보고 있는지 확인 (타입별)
  static bool isViewingChatRoomByType(String? chatRoomId, String chatRoomType) {
    if (chatRoomId == null || _currentChatRoomId == null || _currentChatRoomType == null) {
      return false;
    }
    
    // 채팅방 ID와 타입이 모두 일치하는지 확인
    return _currentChatRoomId == chatRoomId && _currentChatRoomType == chatRoomType;
  }
  
  /// 현재 라우트 정보 가져오기
  static String? get currentRoute => _currentRoute;
  static String? get currentChatRoomId => _currentChatRoomId;
  static String? get currentChatRoomType => _currentChatRoomType;
}
