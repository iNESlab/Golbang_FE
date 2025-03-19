import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // for jsonEncode, jsonDecode

final gameInProgressProvider =
StateNotifierProvider<GameInProgressNotifier, Map<int, bool>>(
      (ref) => GameInProgressNotifier(),
);

class GameInProgressNotifier extends StateNotifier<Map<int, bool>> {
  static const String _storageKey = 'game_in_progress_map';

  GameInProgressNotifier() : super({}) {
    _loadFromStorage();
  }

  /// "게임 중" 상태로 변경
  Future<void> startGame(int eventId) async {
    state = {...state, eventId: true};
    await _saveToStorage();
  }

  /// SharedPreferences에서 Map<int, bool> 로드
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      // "key"가 String 형태이므로, int로 변환
      final Map<int, bool> loadedMap = decoded.map<int, bool>(
            (key, value) => MapEntry(int.parse(key), value as bool),
      );
      state = loadedMap;
    }
  }

  /// SharedPreferences에 Map<int, bool> 저장
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    // state(Map<int, bool>)를 String으로 변환하기 위해 key를 String으로 변환
    final Map<String, bool> stringKeyMap = state.map<String, bool>(
          (key, value) => MapEntry(key.toString(), value),
    );
    final jsonString = jsonEncode(stringKeyMap);
    await prefs.setString(_storageKey, jsonString);
  }
}
