import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:golbang/models/club.dart';
import 'package:golbang/utils/reponsive_utils.dart';
import 'dart:developer'; // 🔧 추가: log 함수 사용

import '../../provider/club/club_state_provider.dart';

class GroupsSection extends ConsumerStatefulWidget {
  const GroupsSection({super.key}); // 🔧 수정: clubs 파라미터 제거

  @override
  ConsumerState<GroupsSection> createState() => _GroupsSectionState();
}

class _GroupsSectionState extends ConsumerState<GroupsSection> {
  final ScrollController _scrollController = ScrollController(); // ScrollController 선언

  @override
  void initState() {
    super.initState();
    // 화면 렌더링 후 클럽 데이터 최신화
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(clubStateProvider.notifier).fetchClubs();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // 메모리 누수 방지를 위해 ScrollController 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // 🔧 수정: clubStateProvider를 ref.watch로 사용하여 실시간 업데이트
        final clubState = ref.watch(clubStateProvider);
        final clubs = clubState.clubList;
        
        // 🔧 디버그: 클럽 데이터와 unreadCount 확인
        log('🔍 GroupsSection build: clubs.length=${clubs.length}');
        if (clubs.isNotEmpty) {
          log('🔍 GroupsSection build: club[0].unreadCount=${clubs[0].unreadCount}');
        }
        
        // 🔧 추가: unreadCount가 변경될 때 강제로 위젯 재빌드
        return _buildClubList(clubs, context, ref);
      },
    );
  }
  
  // 🔧 추가: 클럽 리스트 빌드 메서드 분리
  Widget _buildClubList(List<Club> clubs, BuildContext context, WidgetRef ref) {
    
    double screenWidth = MediaQuery.of(context).size.width;
    Orientation orientation = MediaQuery.of(context).orientation;
    // Dynamic UI settings
    // double avatarRadius = screenWidth > 600 ? screenWidth * 0.1 : screenWidth * 0.08;
    // double padding = screenWidth > 600 ? screenWidth * 0.04 : screenWidth * 0.02;
    // double horizontalMargin = screenWidth > 600 ? screenWidth * 0.04 : screenWidth * 0.03;
    // double textHeight = screenWidth > 600 ? screenWidth * 0.03 : screenWidth * 0.04;
    // double spacing = textHeight / 2;
    // double cardHeight = avatarRadius * 2 + textHeight + spacing + padding;

    double avatarRadius = ResponsiveUtils.getGroupsAvatarRadius(screenWidth, orientation);
    double padding = ResponsiveUtils.getGroupsPadding(screenWidth, orientation);
    double horizontalMargin = ResponsiveUtils.getGroupsHorizontalMargin(screenWidth, orientation);
    double textHeight = ResponsiveUtils.getGroupsTextHeight(screenWidth, orientation);
    double cardHeight = ResponsiveUtils.getGroupsCardHeight(avatarRadius, textHeight, padding);

    return Scrollbar(
      thumbVisibility: true,
      thickness: 5.0,
      controller: _scrollController, // ScrollController 연결

      child: SizedBox(
        height: cardHeight,
        child: ListView.builder(
          controller: _scrollController, // 동일한 ScrollController 연결
          scrollDirection: Axis.horizontal,
          itemCount: clubs.length,
          itemBuilder: (context, index) {
            final club = clubs[index];
            return Padding(
              padding: EdgeInsets.only(right: padding),
              child: GestureDetector(
                onTap: () {
                  ref.read(clubStateProvider.notifier).selectClubById(club.id); // 상태 저장
                  context.push('/app/clubs/${club.id}', extra: {'from': 'home'}); // 🔧 수정: 홈에서 온 경우 표시
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 0.5,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Container(
                            width: avatarRadius * 2,
                            height: avatarRadius * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: club.image.contains('http')
                                  ? DecorationImage(
                                image: NetworkImage(club.image),
                                fit: BoxFit.fill,
                              )
                                  : DecorationImage(
                                image: AssetImage(club.image),
                                fit: BoxFit.fill,
                              )
                            ),
                            child: club.image.startsWith('http')
                                ? Center(
                              child: Text(
                                club.name.substring(0, 1),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                                : null,
                          ),
                        ),
                        // 🔧 추가: 읽지 않은 메시지 개수 Badge (항상 렌더링하여 애니메이션 효과)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: AnimatedContainer(
                            key: ValueKey('unread_${club.id}_${club.unreadCount}'), // 🔧 추가: Key로 강제 재빌드
                            duration: const Duration(milliseconds: 300), // 🔧 추가: 애니메이션 효과
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: club.unreadCount > 0 ? Colors.red : Colors.transparent, // 🔧 수정: 0일 때 투명
                              borderRadius: BorderRadius.circular(12),
                              border: club.unreadCount > 0 ? Border.all(color: Colors.white, width: 2) : null, // 🔧 수정: 0일 때 테두리 없음
                            ),
                            constraints: BoxConstraints(
                              minWidth: club.unreadCount > 0 ? 20 : 0, // 🔧 수정: 0일 때 크기 0
                              minHeight: club.unreadCount > 0 ? 20 : 0, // 🔧 수정: 0일 때 크기 0
                            ),
                            child: club.unreadCount > 0 ? Text(
                              club.unreadCount > 99 ? '99+' : club.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ) : const SizedBox.shrink(), // 🔧 수정: 0일 때 빈 위젯
                          ),
                        ),
                      ],
                    ),
                    Text(
                      club.name,
                      style: TextStyle(
                        fontSize: textHeight,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
