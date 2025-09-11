import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import '../../../../features/event/domain/entities/participant.dart';

class EventGroupPanel extends StatefulWidget {
  final List<Participant> participants;
  final double fontSizeLarge;
  final double fontSizeMedium;

  const EventGroupPanel({
    super.key,
    required this.participants,
    required this.fontSizeLarge,
    required this.fontSizeMedium,
  });

  @override
  State<EventGroupPanel> createState() => _EventGroupPanelState();
}

class _EventGroupPanelState extends State<EventGroupPanel> {
  final Map<int, bool> _isExpandedMap = {};

  Icon _getStatusIcon(String statusType) {
    switch (statusType) {
      case 'PARTY':
        return const Icon(Icons.check_circle, color: Color(0xFF4D08BD));
      case 'ACCEPT':
        return const Icon(Icons.check_circle, color: Color(0xFF08BDBD));
      case 'DENY':
        return const Icon(Icons.cancel, color: Color(0xFFF21B3F));
      case 'PENDING':
        return const Icon(Icons.hourglass_top, color: Colors.grey);
      default:
        return const Icon(Icons.help_outline, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <int, List<Participant>>{};
    for (var p in widget.participants) {
      grouped.putIfAbsent(p.groupType, () => []).add(p);
    }

    final groupKeys = grouped.keys.toList()..sort();

    return ExpansionPanelList(
      expansionCallback: (index, isExpanded) {
        final key = groupKeys[index];
        setState(() {
          _isExpandedMap[key] = !(_isExpandedMap[key] ?? false);
        });
      },
      children: groupKeys.mapIndexed((index, group) {
        final groupMembers = grouped[group]!;

        return ExpansionPanel(
          isExpanded: _isExpandedMap[group] ?? false,
          canTapOnHeader: true,
          headerBuilder: (context, isExpanded) {
            return ListTile(
              title: Text('$group조 (${groupMembers.length}명)', style: TextStyle(fontSize: widget.fontSizeLarge)),
            );
          },
          body: Column(
            children: groupMembers.map((p) {
              final icon = _getStatusIcon(p.statusType);
              final member = p.member;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  backgroundImage: (member?.profileImage != null && member!.profileImage.startsWith('https'))
                      ? NetworkImage(member.profileImage)
                      : null,
                  child: (member?.profileImage == null || member!.profileImage.isEmpty)
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(member?.name ?? 'Unknown', style: TextStyle(fontSize: widget.fontSizeMedium)),
                trailing: icon,
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
