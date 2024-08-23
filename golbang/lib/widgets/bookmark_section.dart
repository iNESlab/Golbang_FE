import 'package:flutter/material.dart';
import '../models/bookmark.dart';

class BookmarkSection extends StatelessWidget {
  final List<Bookmark> bookmarks;

  const BookmarkSection({super.key, required this.bookmarks});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            bookmarks.map((bookmark) => _buildInfoCard(bookmark)).toList(),
      ),
    );
  }

  Widget _buildInfoCard(Bookmark bookmark) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            bookmark.title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            bookmark.value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          if (bookmark.subtitle != null)
            Text(
              bookmark.subtitle!,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          if (bookmark.detail1 != null && bookmark.detail2 != null)
            Column(
              children: [
                Text(
                  bookmark.detail1!,
                  style: const TextStyle(fontSize: 10),
                ),
                Text(
                  bookmark.detail2!,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
