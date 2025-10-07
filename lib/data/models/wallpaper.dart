class Wallpaper {
  Wallpaper({
    required this.imageId,
    required this.imageName,
    required this.imageThumb,
    required this.imageUpload,
    required this.imageUrl,
    required this.type,
    required this.resolution,
    required this.size,
    required this.mime,
    required this.views,
    required this.downloads,
    required this.featured,
    required this.tags,
    required this.categoryId,
    required this.categoryName,
    required this.lastUpdate,
    required this.rewarded,
  });

  final String imageId;
  final String imageName;
  final String imageThumb;
  final String imageUpload;
  final String imageUrl;
  final String type;
  final String resolution;
  final String size;
  final String mime;
  final int views;
  final int downloads;
  final String featured;
  final String tags;
  final String categoryId;
  final String categoryName;
  final String lastUpdate;
  final int rewarded;

  /// Nombre listo para mostrar, con un fallback legible cuando la API responde vacío.
  String get displayName => imageName.isNotEmpty ? imageName : 'Sin nombre';

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      imageId: json['image_id']?.toString() ?? '',
      imageName: json['image_name']?.toString() ?? '',
      imageThumb: json['image_thumb']?.toString() ?? '',
      imageUpload: json['image_upload']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      resolution: json['resolution']?.toString() ?? '',
      size: json['size']?.toString() ?? '',
      mime: json['mime']?.toString() ?? '',
      views: _parseInt(json['views']),
      downloads: _parseInt(json['downloads']),
      featured: json['featured']?.toString() ?? '',
      tags: json['tags']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      lastUpdate: json['last_update']?.toString() ?? '',
      rewarded: _parseInt(json['rewarded']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_id': imageId,
      'image_name': imageName,
      'image_thumb': imageThumb,
      'image_upload': imageUpload,
      'image_url': imageUrl,
      'type': type,
      'resolution': resolution,
      'size': size,
      'mime': mime,
      'views': views,
      'downloads': downloads,
      'featured': featured,
      'tags': tags,
      'category_id': categoryId,
      'category_name': categoryName,
      'last_update': lastUpdate,
      'rewarded': rewarded,
    };
  }

  Wallpaper copyWith({
    String? imageThumb,
  }) {
    return Wallpaper(
      imageId: imageId,
      imageName: imageName,
      imageThumb: imageThumb ?? this.imageThumb,
      imageUpload: imageUpload,
      imageUrl: imageUrl,
      type: type,
      resolution: resolution,
      size: size,
      mime: mime,
      views: views,
      downloads: downloads,
      featured: featured,
      tags: tags,
      categoryId: categoryId,
      categoryName: categoryName,
      lastUpdate: lastUpdate,
      rewarded: rewarded,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
