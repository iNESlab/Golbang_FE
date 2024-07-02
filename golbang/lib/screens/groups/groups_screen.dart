import 'package:flutter/material.dart';
import '../../widgets/group_item.dart';
import '../../widgets/announcement_item.dart';
import 'package:golbang/global_config.dart';

class GroupsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('내 모임', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.add_circle),
                      onPressed: () {},
                    ),
                  ],
                ),
                TextField(
                  decoration: InputDecoration(
                    hintText: '모임명 검색',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  height: 120,
                  child: PageView(
                    children: [
                      GridView.count(
                        crossAxisCount: 3,
                        children: GlobalConfig.groupData.take(6).map((group) {
                          return GroupItem(
                            image: group['image']!,
                            label: group['label']!,
                          );
                        }).toList(),
                      ),
                      GridView.count(
                        crossAxisCount: 3,
                        children: GlobalConfig.groupData.skip(3).take(3).map((group) {
                          return GroupItem(
                            image: group['image']!,
                            label: group['label']!,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('공지사항', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView(
                      children: GlobalConfig.announcementData.map((announcement) {
                        return Dismissible(
                          key: Key(announcement['title']!),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.green,
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text('읽음', style: TextStyle(color: Colors.white)),
                          ),
                          onDismissed: (direction) {
                            // Handle dismissal here
                          },
                          child: AnnouncementItem(
                            title: announcement['title']!,
                            date: announcement['date']!,
                            content: announcement['content']!,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
