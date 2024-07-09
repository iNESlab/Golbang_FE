class Group {
  final String name;
  final bool isNew;

  const Group(this.name, this.isNew);

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      json['name'],
      json['isNew'],
    );
  }
}
