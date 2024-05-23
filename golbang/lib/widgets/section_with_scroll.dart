import 'package:flutter/material.dart';

class SectionWithScroll extends StatelessWidget {
  final String title;
  final Widget child;

  const SectionWithScroll({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final RegExp numberRegExp = RegExp(r'(\d+)');
    final Iterable<Match> matches = numberRegExp.allMatches(title);
    final List<TextSpan> spans = [];
    int start = 0;

    for (final Match match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: title.substring(start, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(color: Colors.green),
      ));
      start = match.end;
    }
    if (start < title.length) {
      spans.add(TextSpan(text: title.substring(start)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  children: spans,
                ),
              ),
              const SizedBox.shrink(),
            ],
          ),
        ),
        SizedBox(height: title.startsWith('내 모임') ? 1 : 4),
        Expanded(
          child: child,
        ),
      ],
    );
  }
}
