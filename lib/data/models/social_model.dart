class SocialModel {
  final String id;
  final String platform;
  final String handle;
  final String url;
  final String icon;

  const SocialModel({
    required this.id,
    required this.platform,
    required this.handle,
    required this.url,
    required this.icon,
  });

  factory SocialModel.fromMap(String id, Map<String, dynamic> map) {
    return SocialModel(
      id: id,
      platform: map['platform'] ?? '',
      handle: map['handle'] ?? '',
      url: map['url'] ?? '',
      icon: map['icon'] ?? '',
    );
  }
}
