import 'package:flutter/material.dart';
import '../models/group.dart';

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
            bool isNew = groups[index].isNew;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isNew ? Colors.green : Colors.transparent,
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
              child: const CircleAvatar(
                radius: 35,
                backgroundColor: Colors.grey,
                backgroundImage: AssetImage('assets/images/dragon.jpeg'),
              ),
            );
          },
        ),
      ),
    );
  }
}
