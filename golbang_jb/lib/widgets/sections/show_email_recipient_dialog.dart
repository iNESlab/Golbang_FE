import 'package:flutter/material.dart';
import '../../models/participant.dart';

Future<List<String>> showEmailRecipientDialog(BuildContext context, List<Participant> participants) async {
  final selected = <String>{};

  return await showDialog<List<String>>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          // 이메일 + 이름 필터링
          final emailEntries = participants
              .map((p) => {
            'email': p.member?.email.trim(),
            'name': p.member?.name ?? "이름 없음",
          })
              .where((entry) => entry['email'] != null && entry['email']!.isNotEmpty)
              .toList();

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
            title: SizedBox(
              width: double.maxFinite,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('받는 사람'),
                  Row(
                    children: [
                      const Text('전체 선택', style: TextStyle(fontSize: 14)),
                      Checkbox(
                        value: isAllSelected,
                        onChanged: toggleAll,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6, // 최대 높이 제한
              ),
              child: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Divider(),
                    ...emailEntries.map((entry) {
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
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              ElevatedButton(
                child: const Text('보내기'),
                onPressed: () {
                  Navigator.of(context).pop(selected.toList());
                },
              ),
            ],
          );
        },
      );
    },
  ) ?? [];
}
