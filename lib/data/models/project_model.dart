class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String link;
  final List<String> tags;
  final String category;
  final String year;

  const ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.link,
    required this.tags,
    required this.category,
    required this.year,
  });

  factory ProjectModel.fromMap(String id, Map<String, dynamic> map) {
    return ProjectModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      link: map['link'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      category: map['category'] ?? '',
      year: map['year'] ?? '',
    );
  }
}
