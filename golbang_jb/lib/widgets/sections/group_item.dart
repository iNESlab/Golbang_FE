import 'package:flutter/material.dart';

class GroupItem extends StatelessWidget {
  final String image;
  final String label;

  const GroupItem({super.key, required this.image, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 90,
          height: 90,
          child: Image.asset(image, fit: BoxFit.cover),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 16)),
      ],
    );
  }
}
