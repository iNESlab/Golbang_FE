// 🚫 라디오 기능 비활성화 - 안드로이드에서 사용하지 않음
/*
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:just_audio/just_audio.dart';

/// 🎵 동기화된 라디오 서비스 (HLS 기반)
class SynchronizedRadioService {
  // WebSocket 연결
  WebSocketChannel? _channel;
  
  // HLS 오디오 플레이어
  AudioPlayer? _hlsPlayer;
  
  // 상태 관리
  bool _isConnected = false;
  bool _isPlaying = false;
  String? _eventId;
  String? _hlsUrl;
  
  // 재연결 관리
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const int _reconnectDelay = 1;  // 지연 시간 단축
  
  // 싱글톤 패턴
  static final SynchronizedRadioService _instance = SynchronizedRadioService._internal();
  factory SynchronizedRadioService() => _instance;
  SynchronizedRadioService._internal();
  
  /// 서비스 초기화
  Future<void> initialize() async {
    try {
      _hlsPlayer = AudioPlayer();
      
      // HLS 스트림 설정 (지연 시간 단축을 위한 버퍼 최적화)
      await _hlsPlayer?.setLoopMode(LoopMode.one);
      await _hlsPlayer?.setVolume(1.0);
      // setBufferSize는 just_audio에서 지원되지 않음
      
      developer.log('🎵 SynchronizedRadioService 초기화 완료');
      
    } catch (e) {
      developer.log('❌ SynchronizedRadioService 초기화 실패: $e');
    }
  }
  
  /// 동기화된 라디오 시작
  Future<bool> startRadio(String eventId) async {
    try {
      if (_isPlaying && _eventId == eventId) {
        developer.log('⚠️ 이미 라디오가 재생 중입니다');
        return true;
      }
      
      _eventId = eventId;
      _isConnected = false; // 연결 상태 초기화
      _isPlaying = false;   // 재생 상태 초기화
      
      // WebSocket 연결 시도
      await _connectToRadio(eventId);
      
      // 연결 시도 후 잠시 대기 (서버 응답 기다림)
      await Future.delayed(Duration(milliseconds: 500));
      
      if (_isConnected) {
        // 라디오 시작 요청
        _sendMessage({
          'type': 'start_radio',
          'event_id': eventId
        });
        
        _isPlaying = true;
        developer.log('🎵 동기화된 라디오 시작: event_$eventId');
        return true;
      } else {
        developer.log('❌ 라디오 연결 실패: 서버에서 연결을 거부했습니다');
        return false;
      }
      
    } catch (e) {
      developer.log('❌ 동기화된 라디오 시작 실패: $e');
      _isConnected = false;
      _isPlaying = false;
      return false;
    }
  }
  
  /// 라디오 중단
  Future<void> stopRadio() async {
    try {
      _isPlaying = false;
      
      // HLS 재생 중단
      await _hlsPlayer?.stop();
      
      // WebSocket 연결 해제
      await _channel?.sink.close();
      _isConnected = false;
      
      developer.log('🛑 동기화된 라디오 중단');
      
    } catch (e) {
      developer.log('❌ 동기화된 라디오 중단 실패: $e');
    }
  }
  
  /// WebSocket 연결
  Future<void> _connectToRadio(String eventId) async {
    try {
      final uri = Uri.parse('ws://localhost:8000/ws/synchronized-radio/club/$eventId/');
      _channel = WebSocketChannel.connect(uri);
      
      // 메시지 수신 리스너
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );
      
      // 연결 상태는 서버에서 radio_connected 메시지를 받을 때만 true로 설정
      developer.log('🔌 동기화 라디오 WebSocket 연결 시도: $eventId');
      
    } catch (e) {
      developer.log('❌ 동기화 라디오 WebSocket 연결 실패: $e');
      _isConnected = false;
      _scheduleReconnect(eventId);
    }
  }
  
  /// 메시지 처리
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'] as String;
      
      developer.log('📨 동기화 라디오 메시지 수신: $type');
      
      switch (type) {
        case 'radio_connected':
          _isConnected = true;
          _reconnectAttempts = 0; // 재연결 시도 횟수 초기화
          developer.log('🎵 동기화 라디오 연결 확인: ${data['message']}');
          break;
          
        case 'hls_stream_url':
          _playHlsStream(data['url'] as String);
          break;
          
        case 'commentary_audio':
          _playCommentary(data['audio_data'] as String);
          break;
          
        case 'stream_info':
          _handleStreamInfo(data);
          break;
          
        default:
          developer.log('⚠️ 알 수 없는 동기화 라디오 메시지: $type');
      }
      
    } catch (e) {
      developer.log('❌ 동기화 라디오 메시지 처리 오류: $e');
    }
  }
  
  /// HLS 스트림 재생 (동기화된 재생!)
  void _playHlsStream(String url) async {
    try {
      _hlsUrl = url;
      await _hlsPlayer?.setUrl(url);
      
      // 연결 상태 확인 후 재생
      if (_isConnected) {
        await _hlsPlayer?.play();
        developer.log('🎵 HLS 스트림 재생 시작: $url');
      } else {
        developer.log('⚠️ 연결되지 않은 상태에서 재생 시도');
      }
      
    } catch (e) {
      developer.log('❌ HLS 스트림 재생 실패: $e');
      _scheduleReconnect(_eventId);
    }
  }
  
  /// 중계멘트 재생
  void _playCommentary(String audioData) async {
    try {
      // HLS 볼륨 낮춤
      await _hlsPlayer?.setVolume(0.2);
      
      // Base64 디코딩하여 임시 파일로 저장
      final audioBytes = base64Decode(audioData);
      final tempFilePath = await _saveAudioToTempFile(audioBytes);
      
      if (tempFilePath != null) {
        // 별도 플레이어로 중계멘트 재생
        final commentaryPlayer = AudioPlayer();
        await commentaryPlayer.setFilePath(tempFilePath);
        await commentaryPlayer.play();
        
        // 중계멘트 완료 시 HLS 볼륨 복원
        commentaryPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            _restoreHlsVolume();
            commentaryPlayer.dispose();
          }
        });
        
        developer.log('🎤 중계멘트 재생 시작');
      }
      
    } catch (e) {
      developer.log('❌ 중계멘트 재생 실패: $e');
      _restoreHlsVolume();
    }
  }
  
  /// HLS 볼륨 복원
  void _restoreHlsVolume() async {
    try {
      await _hlsPlayer?.setVolume(1.0);
      developer.log('🔊 HLS 볼륨 복원');
    } catch (e) {
      developer.log('❌ HLS 볼륨 복원 실패: $e');
    }
  }
  
  /// 스트림 정보 처리
  void _handleStreamInfo(Map<String, dynamic> data) {
    try {
      final isStreaming = data['is_streaming'] as bool;
      final hlsUrl = data['hls_url'] as String;
      final timestamp = data['timestamp'] as String;
      
      developer.log('📊 스트림 정보: streaming=$isStreaming, url=$hlsUrl, time=$timestamp');
      
    } catch (e) {
      developer.log('❌ 스트림 정보 처리 오류: $e');
    }
  }
  
  /// 오디오를 임시 파일로 저장
  Future<String?> _saveAudioToTempFile(List<int> audioBytes) async {
    try {
      // 임시 파일 생성 (MP3 확장자)
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/commentary_${DateTime.now().millisecondsSinceEpoch}.mp3');
      
      await tempFile.writeAsBytes(audioBytes);
      
      // 30초 후 임시 파일 삭제
      Timer(Duration(seconds: 30), () {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      });
      
      return tempFile.path;
      
    } catch (e) {
      developer.log('❌ 임시 파일 저장 실패: $e');
      return null;
    }
  }
  
  /// 메시지 전송
  void _sendMessage(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (e) {
      developer.log('❌ 메시지 전송 실패: $e');
    }
  }
  
  /// 오류 처리
  void _handleError(error) {
    developer.log('❌ 동기화 라디오 WebSocket 오류: $error');
    _isConnected = false;
    _isPlaying = false;
    
    // 진행 중인 이벤트가 없다는 오류일 가능성이 높으므로 재연결하지 않음
    developer.log('⚠️ 라디오 연결 오류로 인해 재연결을 중단합니다.');
  }
  
  /// 연결 해제 처리
  void _handleDisconnect() {
    developer.log('🔌 동기화 라디오 WebSocket 연결 해제');
    _isConnected = false;
    _isPlaying = false;
    
    // 연결이 해제되면 재연결 시도하지 않음 (사용자가 명시적으로 다시 시도해야 함)
    developer.log('⚠️ 라디오 연결이 해제되었습니다. 다시 시도하려면 라디오 버튼을 눌러주세요.');
  }
  
  /// 재연결 스케줄링
  void _scheduleReconnect(String? eventId) {
    if (_reconnectAttempts >= _maxReconnectAttempts || eventId == null) {
      developer.log('❌ 최대 재연결 시도 횟수 초과');
      return;
    }
    
    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts;
    
    developer.log('⏰ $delay초 후 재연결 시도 ($_reconnectAttempts/$_maxReconnectAttempts)');
    
    _reconnectTimer = Timer(Duration(seconds: delay), () {
      _connectToRadio(eventId);
    });
  }
  
  /// 리소스 정리
  Future<void> dispose() async {
    try {
      _reconnectTimer?.cancel();
      await stopRadio();
      
      await _hlsPlayer?.dispose();
      
      developer.log('🧹 SynchronizedRadioService 정리 완료');
      
    } catch (e) {
      developer.log('❌ SynchronizedRadioService 정리 실패: $e');
    }
  }
}
*/

