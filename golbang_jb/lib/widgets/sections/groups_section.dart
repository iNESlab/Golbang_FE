import 'package:flutter/material.dart';
import 'package:golbang/pages/community/community_main.dart';
import 'package:golbang/models/group.dart';

class GroupsSection extends StatelessWidget {
  final List<Group> groups;

  const GroupsSection({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    double screenWidth = MediaQuery.of(context).size.width; // Screen width

    // Set avatar size, padding, and margin based on screen width
    double avatarRadius = screenWidth > 600 ? screenWidth * 0.1 : screenWidth * 0.08; // Avatar size
    double padding = screenWidth > 600 ? screenWidth * 0.04 : screenWidth * 0.02; // Padding inside the card
    double horizontalMargin = screenWidth > 600 ? screenWidth * 0.04 : screenWidth * 0.03; // Horizontal margin between cards

    // Calculate dynamic card height: avatar height + text height + spacing
    double textHeight = screenWidth > 600 ? screenWidth * 0.03 : screenWidth * 0.04; // Dynamic text height
    double spacing = textHeight / 2; // Space between avatar and text
    double cardHeight = avatarRadius * 2 + textHeight + spacing + padding;

    return Scrollbar(
      thumbVisibility: true,
      thickness: 5.0,
      child: SizedBox(
        height: cardHeight, // Dynamically calculated card height
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];

            return Padding(
              padding: EdgeInsets.only(right: padding), // Dynamic padding between items
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommunityMain(
                        communityID: group.id,
                        communityName: group.name,
                        communityImage: group.image!,
                        adminNames: group.getAdminNames(),
                        isAdmin: group.isAdmin,
                      ),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Circle Avatar
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: horizontalMargin), // Dynamic horizontal margin
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
                          image: group.image != null && group.image!.contains('http')
                              ? DecorationImage(
                            image: NetworkImage(group.image!), // 네트워크 이미지
                            fit: BoxFit.fill,
                          )
                              : group.image != null
                              ? DecorationImage(
                            image: AssetImage(group.image!), // 로컬 파일
                            fit: BoxFit.fill,
                          )
                              : null, // 이미지가 없으면 기본값
                        ),
                        child: group.image == null
                            ? Center(
                          child: Text(
                            group.name.substring(0, 1), // 그룹 이름 첫 글자
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                            : null, // 이미지가 있으면 텍스트를 숨김
                      ),
                    ),
                    SizedBox(height: spacing), // Spacing between avatar and text
                    // Group Name
                    Text(
                      group.name,
                      style: TextStyle(
                        fontSize: textHeight, // Dynamic text size
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis, // Handle long names gracefully
                      maxLines: 1, // Ensure the name is single-line
                      textAlign: TextAlign.center, // Center-align the text
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
