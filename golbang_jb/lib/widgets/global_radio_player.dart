// 🚫 라디오 기능 비활성화 - 안드로이드에서 사용하지 않음
/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/global_radio_provider.dart';

class GlobalRadioPlayer extends ConsumerWidget {
  const GlobalRadioPlayer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final radioState = ref.watch(globalRadioProvider);
    final radioNotifier = ref.read(globalRadioProvider.notifier);
    
    // 라디오가 연결되지 않았고 로딩 중도 아니면 숨김
    if (!radioState.isConnected && !radioState.isLoading) {
      return const SizedBox.shrink();
    }

    return Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // 라디오 아이콘
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.radio,
                    color: Colors.blue,
                    size: 28,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 제목과 상태
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        radioState.clubName ?? 'RTMP 라디오',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: radioState.isConnected && radioState.isPlaying 
                                ? Colors.red 
                                : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            radioState.isLoading 
                              ? '연결 중...' 
                              : !radioState.isConnected
                                ? '연결 끊김'
                                : radioState.isPlaying 
                                  ? 'LIVE' 
                                  : '일시정지됨',
                            style: TextStyle(
                              fontSize: 14,
                              color: radioState.isConnected && radioState.isPlaying 
                                ? Colors.red 
                                : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      // 에러 메시지 표시
                      if (radioState.errorMessage != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          radioState.errorMessage!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // 재생/정지 버튼
                if (radioState.isLoading)
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 재생/일시정지 버튼
                      IconButton(
                        onPressed: radioState.isConnected 
                          ? () async {
                              await radioNotifier.togglePlayPause();
                            }
                          : null,
                        icon: Icon(
                          radioState.isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 28,
                          color: radioState.isConnected ? Colors.blue : Colors.grey,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: radioState.isConnected 
                            ? Colors.blue.shade100 
                            : Colors.grey.shade100,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // 정지 버튼
                      IconButton(
                        onPressed: () async {
                          await radioNotifier.stopRadio();
                        },
                        icon: const Icon(
                          Icons.stop,
                          size: 28,
                          color: Colors.grey,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade100,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
  }
}

/// 전역 라디오 플레이어를 포함한 Scaffold 래퍼
class ScaffoldWithRadio extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const ScaffoldWithRadio({
    Key? key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Expanded(child: body),
          const GlobalRadioPlayer(),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
*/
