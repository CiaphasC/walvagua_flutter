class Category {
  Category({
    required this.id,
    required this.name,
    required this.image,
    required this.totalWallpapers,
  });

  final String id;
  final String name;
  final String image;
  final String totalWallpapers;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['category_id']?.toString() ?? '',
      name: json['category_name']?.toString() ?? '',
      image: json['category_image']?.toString() ?? '',
      totalWallpapers: json['total_wallpaper']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': id,
      'category_name': name,
      'category_image': image,
      'total_wallpaper': totalWallpapers,
    };
  }
}
