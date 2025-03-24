import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/pages/community/community_main.dart';
import 'package:golbang/models/club.dart';
import 'package:golbang/utils/reponsive_utils.dart';

import '../../provider/club/club_state_provider.dart';

class GroupsSection extends ConsumerStatefulWidget {
  final List<Club> clubs;
  const GroupsSection({super.key, required this.clubs});

  @override
  ConsumerState<GroupsSection> createState() => _GroupsSectionState();
}

class _GroupsSectionState extends ConsumerState<GroupsSection> {
  final ScrollController _scrollController = ScrollController(); // ScrollController 선언

  @override
  void dispose() {
    _scrollController.dispose(); // 메모리 누수 방지를 위해 ScrollController 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          itemCount: widget.clubs.length,
          itemBuilder: (context, index) {
            final club = widget.clubs[index];
            return Padding(
              padding: EdgeInsets.only(right: padding),
              child: GestureDetector(
                onTap: () {
                  ref.read(clubStateProvider.notifier).selectClub(club); // 상태 저장
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CommunityMain()
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
