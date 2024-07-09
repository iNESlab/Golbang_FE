import 'package:flutter/material.dart';

class GroupItem extends StatelessWidget {
  final String image;
  final String label;

  GroupItem({required this.image, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 10),
      child: Column(
        children: [
          Image.asset(image, width: 60, height: 60),
          SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
