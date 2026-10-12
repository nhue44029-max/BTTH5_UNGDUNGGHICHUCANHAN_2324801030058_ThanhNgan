class Note {
  const Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note copyWith({String? title, String? content, DateTime? updatedAt}) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Note.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final content = json['content'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];
    if (id is! String ||
        title is! String ||
        content is! String ||
        createdAt is! String ||
        updatedAt is! String) {
      throw const FormatException('Dữ liệu ghi chú không đúng định dạng.');
    }
    return Note(
      id: id,
      title: title,
      content: content,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
