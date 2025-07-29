import 'package:flutter/material.dart';
import '../../models/participant.dart';

Future<List<String>> showEmailRecipientDialog(BuildContext context, List<Participant> participants) async {
  final selected = <String>{};
  String searchQuery = '';

  return await showDialog<List<String>>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final emailEntries = participants
              .map((p) => {
            'email': p.member?.email.trim(),
            'name': p.member?.name ?? "이름 없음",
          })
              .where((entry) => entry['email'] != null && entry['email']!.isNotEmpty)
              .toList();

          final filteredEmails = emailEntries.where((entry) {
            final email = entry['email']!.toLowerCase();
            final name = entry['name']!.toLowerCase();
            final query = searchQuery.toLowerCase();
            return email.contains(query) || name.contains(query);
          }).toList();

          final allEmails = emailEntries.map((e) => e['email']!).toList();
          final isAllSelected = selected.length == allEmails.length;

          void toggleAll(bool? checked) {
            setState(() {
              if (checked == true) {
                selected.addAll(allEmails);
              } else {
                selected.clear();
              }
            });
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20.0)),
            ),
            titlePadding: EdgeInsets.zero,
            title: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                children: [
                  const Text(
                    '받는 사람',
                    style: TextStyle(color: Colors.green, fontSize: 20),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      toggleAll(!isAllSelected);
                    },
                    child: Text(
                      isAllSelected ? '전체 해제' : '전체 선택',
                      style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 검색창
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: TextField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: '이름 또는 이메일 검색',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 이메일 리스트
                      ...filteredEmails.isEmpty
                          ? [const Center(child: Text('검색 결과가 없습니다.'))]
                          : filteredEmails.map((entry) {
                        final email = entry['email']!;
                        final name = entry['name']!;
                        final isChecked = selected.contains(email);

                        return CheckboxListTile(
                          title: Text(name),
                          subtitle: Text(email),
                          value: isChecked,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selected.add(email);
                              } else {
                                selected.remove(email);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(selected.toList());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('보내기'),
                ),
              ),
            ],
          );
        },
      );
    },
  ) ?? [];
}
