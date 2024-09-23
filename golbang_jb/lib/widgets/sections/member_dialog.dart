import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golbang/models/profile/get_event_result_participants_ranks.dart';

import '../../repoisitory/secure_storage.dart';
import '../../services/user_service.dart';

class MemberDialog extends ConsumerStatefulWidget {
  final List<GetEventResultParticipantsRanks> selectedMembers;
  final ValueChanged<List<GetEventResultParticipantsRanks>> onMembersSelected;

  MemberDialog({
    required this.selectedMembers,
    required this.onMembersSelected,
  });

  @override
  _MemberDialogState createState() => _MemberDialogState();
}

class _MemberDialogState extends ConsumerState<MemberDialog> {
  late List<GetEventResultParticipantsRanks> tempSelectedMembers;

  @override
  void initState() {
    super.initState();
    tempSelectedMembers = List.from(widget.selectedMembers);
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.watch(secureStorageProvider);
    final UserService userService = UserService(storage);

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      titlePadding: EdgeInsets.zero,
      title: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(),
            Text(
              '멤버 추가',
              style: TextStyle(color: Colors.green, fontSize: 25),
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop(tempSelectedMembers);
              },
            ),
          ],
        ),
      ),
      content: Container(
        color: Colors.white,
        width: MediaQuery.of(context).size.width * 0.9,
        child: FutureBuilder<List<GetEventResultParticipantsRanks>>(
          future: userService.getUserProfileList(), // 이 메서드가 위젯 생성 시 자동으로 호출됩니다.
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No users found.'));
            } else {
              final users = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    leading: CircleAvatar(
                      // backgroundImage: NetworkImage(),
                      backgroundImage: users[index].profileImage.startsWith('http')
                          ? NetworkImage(users[index].profileImage)
                          : AssetImage(users[index].profileImage) as ImageProvider,
                    ),
                    title: Text(users[index].name),
                    trailing: Checkbox(
                      value: tempSelectedMembers.contains(users[index]),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value != null && value) {
                            tempSelectedMembers.add(users[index]);
                            print('selectedMember[$index]: ${tempSelectedMembers[index]}');
                          } else {
                            tempSelectedMembers.remove(users[index]);
                          }
                        });
                      },
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      actions: <Widget>[
        Center(
          child: ElevatedButton(
            onPressed: () {
                Navigator.of(context).pop(tempSelectedMembers);
            },
            child: Text('완료'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ),
      ],
    );
  }
}
