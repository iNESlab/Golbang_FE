// 🚫 라디오 기능 비활성화 - 안드로이드에서 사용하지 않음
/*
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;

/// 🎵 RTMP 기반 라디오 서비스
/// nginx-rtmp 미디어 서버를 사용한 안정적인 라이브 스트리밍
class RTMPRadioService {
  // WebSocket 연결
  WebSocketChannel? _channel;
  
  // HLS 오디오 플레이어
  AudioPlayer? _hlsPlayer;
  
  // 상태 관리
  bool _isConnected = false;
  bool _isPlaying = false;
  int? _clubId;
  String? _hlsUrl;
  
  // 재연결 관리
  Timer? _reconnectTimer;
  Timer? _streamStatusTimer; // HTTP 폴링 타이머
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const int _reconnectDelay = 2;
  
  // 상태 스트림
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  final StreamController<bool> _playingController = StreamController<bool>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();
  
  // 싱글톤 패턴
  static final RTMPRadioService _instance = RTMPRadioService._internal();
  factory RTMPRadioService() => _instance;
  RTMPRadioService._internal();
  
  // Getters
  bool get isConnected => _isConnected;
  bool get isPlaying => _isPlaying;
  int? get clubId => _clubId;
  String? get hlsUrl => _hlsUrl;
  
  // Streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<bool> get playingStream => _playingController.stream;
  Stream<String> get errorStream => _errorController.stream;
  
  /// 서비스 초기화
  Future<void> initialize() async {
    try {
      _hlsPlayer = AudioPlayer();
      
      // HLS 스트림 설정 (Safari 호환성 및 지연 시간 최적화)
      await _hlsPlayer?.setLoopMode(LoopMode.off); // 라이브 스트림은 루프 없음
      await _hlsPlayer?.setVolume(1.0);
      
      // 플레이어 상태 리스너
      _hlsPlayer?.playerStateStream.listen((state) {
        bool playing = state.playing && state.processingState != ProcessingState.completed;
        if (_isPlaying != playing) {
          _isPlaying = playing;
          _playingController.add(_isPlaying);
          developer.log('🎵 플레이어 상태 변경: ${playing ? "재생 중" : "정지됨"}');
        }
      });
      
      // 에러 리스너
      _hlsPlayer?.playbackEventStream.listen((event) {
        // 재생 이벤트 처리 (필요시)
      }, onError: (error) {
        developer.log('❌ 오디오 플레이어 오류: $error');
        _errorController.add('오디오 재생 오류: $error');
      });
      
      developer.log('🎵 RTMPRadioService 초기화 완료');
      
    } catch (e) {
      developer.log('❌ RTMPRadioService 초기화 실패: $e');
      _errorController.add('서비스 초기화 실패: $e');
    }
  }
  
  /// RTMP 라디오 연결 및 재생 시작
  Future<bool> startRadio(int clubId) async {
    try {
      developer.log('🎵 RTMP 라디오 시작: 클럽 $clubId');
      
      if (_isConnected && _clubId == clubId) {
        developer.log('🎵 이미 연결된 클럽입니다');
        return true;
      }
      
      // 기존 연결 정리
      await stopRadio();
      
      _clubId = clubId;
      
      // WebSocket 연결 (서버에서 이벤트 체크)
      bool connected = await _connectWebSocket();
      if (!connected) {
        return false;
      }
      
      // 연결 성공 후 잠시 대기 (스트림 정보 수신 대기)
      await Future.delayed(Duration(milliseconds: 500));
      
      // 즉시 HTTP API로 현재 스트림 상태 확인 (해설 중인지 체크)
      await _checkStreamStatusOnce();
      
      // HLS 재생 시작
      if (_hlsUrl != null) {
        await _startHLSPlayback();
        
        // HTTP 폴링 시작 (스트림 상태 확인)
        _startStreamStatusPolling();
        
        return true;
      } else {
        developer.log('❌ HLS URL을 받지 못했습니다');
        return false;
      }
      
    } catch (e) {
      developer.log('❌ 라디오 시작 실패: $e');
      _errorController.add('라디오 시작 실패: $e');
      return false;
    }
  }
  
  /// 라디오 중지
  Future<void> stopRadio() async {
    try {
      developer.log('🛑 RTMP 라디오 중지');
      
      // HLS 재생 중지
      await _hlsPlayer?.stop();
      
      // WebSocket 연결 해제
      await _disconnectWebSocket();
      
      // 상태 초기화
      _clubId = null;
      _hlsUrl = null;
      _isConnected = false;
      _isPlaying = false;
      _reconnectAttempts = 0;
      
      // 타이머 정리
      _reconnectTimer?.cancel();
      _reconnectTimer = null;
      _streamStatusTimer?.cancel();
      _streamStatusTimer = null;
      
      // 상태 알림
      _connectionController.add(false);
      _playingController.add(false);
      
    } catch (e) {
      developer.log('❌ 라디오 중지 오류: $e');
    }
  }
  
  /// 재생/일시정지 토글
  Future<void> togglePlayPause() async {
    try {
      if (_hlsPlayer == null || _hlsUrl == null) {
        developer.log('❌ 플레이어나 URL이 없습니다');
        return;
      }
      
      if (_isPlaying) {
        await _hlsPlayer?.pause();
        developer.log('⏸️ 재생 일시정지');
      } else {
        await _hlsPlayer?.play();
        developer.log('▶️ 재생 재개');
      }
      
    } catch (e) {
      developer.log('❌ 재생/일시정지 오류: $e');
      _errorController.add('재생 제어 오류: $e');
    }
  }
  
  /// WebSocket 연결
  Future<bool> _connectWebSocket() async {
    try {
      // 기존 연결 정리
      await _disconnectWebSocket();
      
      // 새 WebSocket 연결 (RTMP 라디오 엔드포인트 사용)
      String wsUrl = 'ws://localhost:8000/ws/rtmp-radio/club/$_clubId/';
      developer.log('🔌 WebSocket 연결 시도: $wsUrl');
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // 메시지 리스너
      _channel?.stream.listen(
        _handleWebSocketMessage,
        onError: _handleWebSocketError,
        onDone: _handleWebSocketDisconnect,
        cancelOnError: false,
      );
      
      // 연결 확인을 위한 핑 전송
      _sendMessage({'type': 'ping'});
      
      _isConnected = true;
      _connectionController.add(true);
      _reconnectAttempts = 0;
      
      developer.log('✅ WebSocket 연결 성공');
      return true;
      
    } catch (e) {
      developer.log('❌ WebSocket 연결 실패: $e');
      
      // 🔧 추가: 이벤트 없음으로 인한 연결 실패인지 확인
      if (e.toString().contains('Connection to') && e.toString().contains('was not upgraded')) {
        _errorController.add('진행 중인 이벤트가 없어서 라디오를 시작할 수 없습니다');
      } else {
        _errorController.add('서버 연결 실패: $e');
      }
      
      return false;
    }
  }
  
  /// WebSocket 연결 해제
  Future<void> _disconnectWebSocket() async {
    try {
      _channel?.sink.close();
      _channel = null;
      _isConnected = false;
      
    } catch (e) {
      developer.log('❌ WebSocket 연결 해제 오류: $e');
    }
  }
  
  /// WebSocket 메시지 처리
  void _handleWebSocketMessage(dynamic message) {
    try {
      Map<String, dynamic> data = json.decode(message);
      String messageType = data['type'] ?? '';
      
      developer.log('📨 WebSocket 메시지: $messageType');
      
      switch (messageType) {
        case 'stream_info':
          // 스트림 정보 수신
          _hlsUrl = data['hls_url'];
          developer.log('🎵 HLS URL 수신: $_hlsUrl');
          
          // 자동으로 재생 시작
          if (_hlsUrl != null) {
            _startHLSPlayback();
          }
          break;
          
        case 'commentary_started':
          developer.log('🎤 해설 시작: ${data['message']}');
          break;
          
        case 'commentary_ended':
          developer.log('🎤 해설 종료: ${data['message']}');
          break;
          
        case 'status_update':
          developer.log('📊 상태 업데이트: ${data['status']}');
          break;
          
        case 'error':
          String errorMsg = data['message'] ?? '알 수 없는 오류';
          developer.log('❌ 서버 오류: $errorMsg');
          _errorController.add('서버 오류: $errorMsg');
          break;
          
        case 'pong':
          // 핑 응답 - 연결 유지 확인
          break;
          
        case 'stream_change':
          _handleStreamChange(data);
          break;
          
        default:
          developer.log('❓ 알 수 없는 메시지 타입: $messageType');
      }
      
    } catch (e) {
      developer.log('❌ WebSocket 메시지 처리 오류: $e');
    }
  }
  
  /// WebSocket 오류 처리
  void _handleWebSocketError(error) {
    developer.log('❌ WebSocket 오류: $error');
    
    // 🔧 추가: 이벤트 없음으로 인한 오류인지 확인
    if (error.toString().contains('Connection to') && error.toString().contains('was not upgraded')) {
      _errorController.add('진행 중인 이벤트가 없어서 라디오를 시작할 수 없습니다');
      // 이벤트 없음이면 재연결 시도 안 함
      return;
    }
    
    _errorController.add('연결 오류: $error');
    _isConnected = false;
    _connectionController.add(false);
    
    // 자동 재연결 시도
    _scheduleReconnect();
  }
  
  /// WebSocket 연결 해제 처리
  void _handleWebSocketDisconnect() {
    developer.log('👋 WebSocket 연결 해제됨');
    _isConnected = false;
    _connectionController.add(false);
    
    // 🔧 추가: 이벤트 없음으로 인한 연결 해제인지 확인
    // 서버에서 이벤트 없으면 연결을 끊으므로 재연결 시도 안 함
    developer.log('❌ 이벤트가 없어서 라디오를 시작할 수 없습니다');
    _errorController.add('진행 중인 이벤트가 없어서 라디오를 시작할 수 없습니다');
    
    // 이벤트 없음이면 재연결 시도 안 함
    return;
  }
  
  /// 재연결 스케줄링
  void _scheduleReconnect() {
    if (_reconnectTimer != null || _reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }
    
    _reconnectAttempts++;
    developer.log('🔄 재연결 시도 $_reconnectAttempts/$_maxReconnectAttempts');
    
    _reconnectTimer = Timer(Duration(seconds: _reconnectDelay), () async {
      _reconnectTimer = null;
      
      if (_clubId != null) {
        bool success = await _connectWebSocket();
        if (!success && _reconnectAttempts < _maxReconnectAttempts) {
          _scheduleReconnect();
        }
      }
    });
  }
  
  /// WebSocket 메시지 전송
  void _sendMessage(Map<String, dynamic> message) {
    try {
      if (_channel != null && _isConnected) {
        _channel?.sink.add(json.encode(message));
      }
    } catch (e) {
      developer.log('❌ 메시지 전송 오류: $e');
    }
  }
  
  /// 스트림 변경 처리
  void _handleStreamChange(Map<String, dynamic> data) {
    try {
      String action = data['action'] ?? '';
      String newHlsUrl = data['hls_url'] ?? '';
      String streamKey = data['stream_key'] ?? '';
      
      developer.log('🔄 스트림 변경: $action -> $streamKey');
      
      if (action == 'commentary_start') {
        // 해설 스트림으로 전환
        developer.log('🎤 해설 스트림으로 전환: $newHlsUrl');
        _switchToStream(newHlsUrl);
      } else if (action == 'commentary_end') {
        // 배경음악 스트림으로 복원
        developer.log('🎵 배경음악 스트림으로 복원: $newHlsUrl');
        _switchToStream(newHlsUrl);
      }
      
    } catch (e) {
      developer.log('❌ 스트림 변경 처리 오류: $e');
    }
  }
  
  /// 스트림 전환
  Future<void> _switchToStream(String newHlsUrl) async {
    try {
      if (_hlsPlayer == null) {
        developer.log('❌ 플레이어가 없습니다');
        return;
      }
      
      developer.log('🔄 스트림 전환 중: $newHlsUrl');
      
      // 새 스트림으로 전환
      await _hlsPlayer?.setUrl(newHlsUrl);
      await _hlsPlayer?.play();
      
      // URL 업데이트
      _hlsUrl = newHlsUrl;
      
      developer.log('✅ 스트림 전환 완료');
      
    } catch (e) {
      developer.log('❌ 스트림 전환 실패: $e');
      _errorController.add('스트림 전환 실패: $e');
    }
  }

  /// HLS 재생 시작
  Future<void> _startHLSPlayback() async {
    try {
      if (_hlsUrl == null || _hlsPlayer == null) {
        developer.log('❌ HLS URL 또는 플레이어가 없습니다');
        return;
      }
      
      developer.log('🎵 HLS 재생 시작: $_hlsUrl');
      
      // HLS 스트림 설정 및 재생
      await _hlsPlayer?.setUrl(_hlsUrl!);
      await _hlsPlayer?.play();
      
      developer.log('✅ HLS 재생 시작됨');
      
    } catch (e) {
      developer.log('❌ HLS 재생 시작 실패: $e');
      _errorController.add('스트림 재생 실패: $e');
    }
  }
  
  /// 리소스 정리
  Future<void> dispose() async {
    try {
      await stopRadio();
      
      // 스트림 컨트롤러 정리
      await _connectionController.close();
      await _playingController.close();
      await _errorController.close();
      
      // 오디오 플레이어 정리
      await _hlsPlayer?.dispose();
      _hlsPlayer = null;
      
      developer.log('🗑️ RTMPRadioService 리소스 정리 완료');
      
    } catch (e) {
      developer.log('❌ 리소스 정리 오류: $e');
    }
  }
  
  /// HTTP 폴링으로 스트림 상태 확인 시작
  void _startStreamStatusPolling() {
    if (_clubId == null) return;
    
    developer.log('🔄 스트림 상태 폴링 시작: 클럽 $_clubId');
    log('🔄 [RTMP] 스트림 상태 폴링 시작: 클럽 $_clubId');
    
    _streamStatusTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      _checkStreamStatus();
    });
  }
  

  /// 스트림 상태 한 번만 확인 (라디오 시작 시)
  Future<void> _checkStreamStatusOnce() async {
    if (_clubId == null) return;
    
    log('🔍 [RTMP] 초기 스트림 상태 확인 중... 클럽 $_clubId');
    
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/chat/radio/status/$_clubId/'),
        headers: {'Content-Type': 'application/json'},
      );
      
      log('📡 [RTMP] 초기 API 응답: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('📄 [RTMP] 초기 응답 데이터: $data');
        
        if (data['success'] == true) {
          final currentStreamUrl = data['current_stream_url'];
          
          // 현재 활성 스트림이 있으면 해당 URL로 설정
          if (currentStreamUrl != null) {
            log('🎯 [RTMP] 활성 스트림 감지: $currentStreamUrl');
            _hlsUrl = currentStreamUrl;
          } else {
            log('🎵 [RTMP] 활성 스트림 없음, WebSocket URL 사용');
          }
        }
      }
    } catch (e) {
      log('❌ [RTMP] 초기 스트림 상태 확인 오류: $e');
      developer.log('❌ 초기 스트림 상태 확인 오류: $e');
    }
  }

  /// 스트림 상태 확인 (주기적 폴링용)
  Future<void> _checkStreamStatus() async {
    if (_clubId == null) return;
    
    log('🔍 [RTMP] 스트림 상태 확인 중... 클럽 $_clubId');
    
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/v1/chat/radio/status/$_clubId/'),
        headers: {'Content-Type': 'application/json'},
      );
      
      log('📡 [RTMP] API 응답: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        log('📄 [RTMP] 응답 데이터: $data');
        
        if (data['success'] == true) {
          final currentStreamUrl = data['current_stream_url'];
          log('🎵 [RTMP] 현재 스트림: $_hlsUrl');
          log('🎵 [RTMP] 새 스트림: $currentStreamUrl');
          
          // 현재 재생 중인 URL과 다르면 전환
          if (currentStreamUrl != null && currentStreamUrl != _hlsUrl) {
            log('🔄 [RTMP] 스트림 URL 변경 감지!!! $_hlsUrl -> $currentStreamUrl');
            developer.log('🔄 스트림 URL 변경 감지: $_hlsUrl -> $currentStreamUrl');
            await _switchToStream(currentStreamUrl);
          }
        }
      }
    } catch (e) {
      log('❌ [RTMP] 스트림 상태 확인 오류: $e');
      developer.log('❌ 스트림 상태 확인 오류: $e');
      // 에러가 발생해도 폴링은 계속 진행
    }
  }
}
*/
