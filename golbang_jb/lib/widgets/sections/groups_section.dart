import 'package:flutter/material.dart';
import 'package:golbang/pages/community/community_main.dart';
import 'package:golbang/models/group.dart';
import 'package:golbang/widgets/sections/group_item.dart';
import 'package:golbang/pages/community/community_main.dart';

class GroupsSection extends StatelessWidget {
  final List<Group> groups;

  const GroupsSection({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      thumbVisibility: true,
      thickness: 5.0,
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommunityMain(
                        communityName: group.name,
                        communityImage: group.image!,
                        adminName: group.getAdminName(),
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 0.5,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey,
                    backgroundImage: AssetImage(group.image!),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
