import 'package:flutter/material.dart';
import 'package:golbang/global_config.dart';

class MemberDialog extends StatefulWidget {
  final List<String> selectedMembers;
  final ValueChanged<List<String>> onMembersSelected;

  MemberDialog({required this.selectedMembers, required this.onMembersSelected});

  @override
  _MemberDialogState createState() => _MemberDialogState();
}

class _MemberDialogState extends State<MemberDialog> {
  late List<String> tempSelectedMembers;

  @override
  void initState() {
    super.initState();
    tempSelectedMembers = List.from(widget.selectedMembers);
  }

  @override
  Widget build(BuildContext context) {
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: '이름 또는 닉네임으로 검색',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Container(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: users.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage(users[index].profileImage!),
                      ),
                      title: Text(users[index].fullname!),
                      trailing: Checkbox(
                        value: tempSelectedMembers.contains(users[index].fullname),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value != null && value) {
                              tempSelectedMembers.add(users[index].fullname!);
                            } else {
                              tempSelectedMembers.remove(users[index].fullname);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
