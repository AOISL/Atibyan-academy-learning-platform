class Section {
  final String id;
  final String title;
  final String content;

  Section({required this.id, required this.title, required this.content});

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'content': content};
  }
}
