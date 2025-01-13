import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ScreenSizeProvider 정의
final screenSizeProvider = StateNotifierProvider<ScreenSizeNotifier, Size>((ref) {
  return ScreenSizeNotifier();
});

class ScreenSizeNotifier extends StateNotifier<Size> {
  ScreenSizeNotifier() : super(Size.zero);

  void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (state.width != size.width || state.height != size.height) {
      state = size; // 새로운 화면 크기로 상태 갱신
    }
  }
}
