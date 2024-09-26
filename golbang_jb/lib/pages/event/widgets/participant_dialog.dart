import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/profile/member_profile.dart';
import '../../../repoisitory/secure_storage.dart';
import '../../../services/club_member_service.dart';

class ParticipantDialog extends ConsumerStatefulWidget {
  final List<ClubMemberProfile> selectedParticipants;
  final int clubId;

  ParticipantDialog({
    required this.selectedParticipants,
    required this.clubId,
  });

  @override
  _ParticipantDialogState createState() => _ParticipantDialogState();
}

class _ParticipantDialogState extends ConsumerState<ParticipantDialog> {
  List<ClubMemberProfile> tempSelectedParticipants = [];
  List<ClubMemberProfile> allParticipants = [];
  bool isLoading = true;
  late ClubMemberService _clubMemberService;

  @override
  void initState() {
    super.initState();
    tempSelectedParticipants = List.from(widget.selectedParticipants);
    _clubMemberService = ClubMemberService(ref.read(secureStorageProvider));
    _fetchParticipants();
  }

  Future<void> _fetchParticipants() async {
    try {
      List<ClubMemberProfile> participants = await _clubMemberService.getClubMemberProfileList(club_id: widget.clubId);
      setState(() {
        allParticipants = participants;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching participants: $e");
      setState(() {
        isLoading = false;
      });
    }
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
              '참여자 추가',
              style: TextStyle(color: Colors.green, fontSize: 25),
            ),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                Navigator.of(context).pop(tempSelectedParticipants);
              },
            ),
          ],
        ),
      ),
      content: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
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
                onChanged: (value) {
                  setState(() {
                    // 검색 결과 필터링
                    allParticipants.retainWhere((participant) =>
                        participant.name.toLowerCase().contains(value.toLowerCase()));
                  });
                },
              ),
              SizedBox(height: 10),
              Container(
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allParticipants.length,
                  itemBuilder: (BuildContext context, int index) {
                    final participant = allParticipants[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: participant.profileImage.startsWith('http')
                            ? NetworkImage(participant.profileImage)
                            : AssetImage(participant.profileImage) as ImageProvider,
                      ),
                      title: Text(participant.name),
                      trailing: Checkbox(
                        value: tempSelectedParticipants.contains(participant),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value != null && value) {
                              tempSelectedParticipants.add(participant);
                            } else {
                              tempSelectedParticipants.remove(participant);
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
              Navigator.of(context).pop(tempSelectedParticipants);
            },
            child: Text('완료'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white, // 텍스트 색상을 흰색으로 설정
              minimumSize: Size(double.infinity, 50),
            ),
          ),
        ),
      ],
    );
  }
}
