class ServiceModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final List<String> features;

  const ServiceModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.features,
  });

  factory ServiceModel.fromMap(String id, Map<String, dynamic> map) {
    return ServiceModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? '',
      features: List<String>.from(map['features'] ?? []),
    );
  }
}
