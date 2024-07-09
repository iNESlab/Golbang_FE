class Bookmark {
  final String title;
  final String value;
  final String? subtitle;
  final String? detail1;
  final String? detail2;

  const Bookmark(this.title, this.value, [this.subtitle, this.detail1, this.detail2]);

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      json['title'],
      json['value'],
      json['subtitle'],
      json['detail1'],
      json['detail2'],
    );
  }
}
