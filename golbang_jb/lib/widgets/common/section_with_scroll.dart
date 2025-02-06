import 'package:flutter/material.dart';
import 'package:golbang/utils/reponsive_utils.dart';

class SectionWithScroll extends StatelessWidget {
  final String title;
  final Widget child;

  const SectionWithScroll({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width; // 화면 너비
    Orientation orientation = MediaQuery.of(context).orientation;
    double fontSizeTitle = ResponsiveUtils.getSWSTitleFS(screenWidth, orientation);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: fontSizeTitle,
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
