import 'package:flutter/material.dart';

class SectionWithScroll extends StatelessWidget {
  final String title;
  final Widget child;

  const SectionWithScroll({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: child,
        ),
      ],
    );
  }
}
