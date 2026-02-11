class UserPhoto {
  final String url;
  final bool isPrimary;
  final int orderIndex;
  final DateTime uploadedAt;

  const UserPhoto({
    required this.url,
    this.isPrimary = false,
    this.orderIndex = 0,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'isPrimary': isPrimary,
      'orderIndex': orderIndex,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  factory UserPhoto.fromMap(Map<String, dynamic> map) {
    return UserPhoto(
      url: map['url'] ?? '',
      isPrimary: map['isPrimary'] ?? false,
      orderIndex: map['orderIndex'] ?? 0,
      uploadedAt: map['uploadedAt'] != null 
          ? DateTime.tryParse(map['uploadedAt']) ?? DateTime.now() 
          : DateTime.now(),
    );
  }
}
