// 🚫 라디오 기능 비활성화 - 안드로이드에서 사용하지 않음
/*
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/rtmp_radio_service.dart';

class GlobalRadioState {
  final bool isConnected;
  final bool isPlaying;
  final bool isLoading;
  final int? currentClubId;
  final String? clubName;
  final String? errorMessage;

  const GlobalRadioState({
    this.isConnected = false,
    this.isPlaying = false,
    this.isLoading = false,
    this.currentClubId,
    this.clubName,
    this.errorMessage,
  });

  GlobalRadioState copyWith({
    bool? isConnected,
    bool? isPlaying,
    bool? isLoading,
    int? currentClubId,
    String? clubName,
    String? errorMessage,
  }) {
    return GlobalRadioState(
      isConnected: isConnected ?? this.isConnected,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      currentClubId: currentClubId ?? this.currentClubId,
      clubName: clubName ?? this.clubName,
      errorMessage: errorMessage,
    );
  }
}

class GlobalRadioNotifier extends StateNotifier<GlobalRadioState> {
  final RTMPRadioService _radioService = RTMPRadioService();
  
  GlobalRadioNotifier() : super(const GlobalRadioState()) {
    _initialize();
  }
  
  Future<void> _initialize() async {
    await _radioService.initialize();
    
    // 상태 스트림 구독
    _radioService.connectionStream.listen((connected) {
      state = state.copyWith(isConnected: connected);
    });
    
    _radioService.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing, isLoading: false);
    });
    
    _radioService.errorStream.listen((error) {
      state = state.copyWith(errorMessage: error, isLoading: false);
    });
  }
  
  /// RTMP 라디오 시작
  Future<bool> startRadio(int clubId, String clubName) async {
    if (state.isPlaying && state.currentClubId == clubId) {
      return true;
    }
    
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final success = await _radioService.startRadio(clubId);
      if (success) {
        state = state.copyWith(
          currentClubId: clubId,
          clubName: clubName,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '라디오 시작 실패: $e',
      );
      return false;
    }
  }
  
  /// 라디오 정지
  Future<void> stopRadio() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await _radioService.stopRadio();
      state = const GlobalRadioState(); // 모든 상태 초기화
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '라디오 정지 실패: $e',
      );
    }
  }
  
  /// 라디오 토글
  Future<bool> toggleRadio(int clubId, String clubName) async {
    if (state.isPlaying && state.currentClubId == clubId) {
      await stopRadio();
      return false;
    } else {
      return await startRadio(clubId, clubName);
    }
  }
  
  /// 재생/일시정지 토글
  Future<void> togglePlayPause() async {
    try {
      await _radioService.togglePlayPause();
    } catch (e) {
      state = state.copyWith(errorMessage: '재생 제어 실패: $e');
    }
  }
  
  @override
  void dispose() {
    // 라디오 서비스는 글로벌 싱글톤이므로 dispose하지 않음
    // (앱 종료 시에만 정리되어야 함)
    super.dispose();
  }
}

final globalRadioProvider = StateNotifierProvider<GlobalRadioNotifier, GlobalRadioState>(
  (ref) {
    // 앱 전체에서 유지되도록 설정
    ref.keepAlive();
    return GlobalRadioNotifier();
  },
);
*/
