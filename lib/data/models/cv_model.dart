class CvModel {
  final String id;
  final String downloadUrl;
  final String lastUpdated;
  final List<String> highlights;
  final String previewUrl;

  const CvModel({
    required this.id,
    required this.downloadUrl,
    required this.lastUpdated,
    required this.highlights,
    required this.previewUrl,
  });

  factory CvModel.fromMap(String id, Map<String, dynamic> map) {
    return CvModel(
      id: id,
      downloadUrl: map['downloadUrl'] ?? '',
      lastUpdated: map['lastUpdated'] ?? '',
      highlights: List<String>.from(map['highlights'] ?? []),
      previewUrl: map['previewUrl'] ?? '',
    );
  }
}
