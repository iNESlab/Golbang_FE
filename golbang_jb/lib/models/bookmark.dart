class Bookmark {
  final String title;
  final String score;
  final String description;
  final String date;

  Bookmark(this.title, this.score, this.description, [this.date = '']);

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      json['title'],
      json['score'],
      json['description'],
      json['date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'score': score,
      'description': description,
      'date': date,
    };
  }
}
