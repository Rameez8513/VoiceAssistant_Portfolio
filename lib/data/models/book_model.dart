class BookModel {
  final String id;
  final String title;
  final String author;
  final String description;
  final String status;
  final String coverColor;
  final String link;

  const BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.status,
    required this.coverColor,
    required this.link,
  });

  factory BookModel.fromMap(String id, Map<String, dynamic> map) {
    return BookModel(
      id: id,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? '',
      coverColor: map['coverColor'] ?? '#8B5CF6',
      link: map['link'] ?? '',
    );
  }
}
