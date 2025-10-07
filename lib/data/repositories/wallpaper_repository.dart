import '../models/category.dart';
import '../models/paged_response.dart';
import '../models/wallpaper.dart';
import '../services/api_service.dart';

class WallpaperRepository {
  WallpaperRepository(this._api);

  final ApiService _api;

  Future<PagedResponse<Wallpaper>> fetchWallpapers({
    required int page,
    required int count,
    required String filter,
    required String order,
    required String category,
  }) async {
    final response = await _api.get(
      'api.php',
      query: <String, dynamic>{
        'get_new_wallpapers': '',
        'page': page,
        'count': count,
        'filter': filter,
        'order': order,
        'category': category,
      },
    );
    final posts = (response['posts'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => Wallpaper.fromJson(_normalizeWallpaperJson(Map<String, dynamic>.from(item as Map))))
        .toList();
    final pages = _parseInt(response['pages'], defaultValue: 1);
    final total = _parseInt(response['count_total'], defaultValue: posts.length);
    return PagedResponse<Wallpaper>(
      items: posts,
      page: page,
      totalPages: pages,
      totalItems: total,
    );
  }

  Future<List<Wallpaper>> searchWallpapers({
    required int page,
    required int count,
    required String keyword,
    required String order,
  }) async {
    final response = await _api.get(
      'api.php',
      query: <String, dynamic>{
        'get_search': '',
        'page': page,
        'count': count,
        'search': keyword,
        'order': order,
      },
    );
    final posts = (response['posts'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => Wallpaper.fromJson(_normalizeWallpaperJson(Map<String, dynamic>.from(item as Map))))
        .toList();
    return posts;
  }

  Future<List<Category>> fetchCategories() async {
    final response = await _api.get(
      'api.php',
      query: const <String, dynamic>{
        'get_categories': '',
      },
    );
    final categories = (response['categories'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => Category.fromJson(_normalizeCategoryJson(Map<String, dynamic>.from(item as Map))))
        .toList();
    return categories;
  }

  Future<List<Category>> searchCategories(String keyword) async {
    final response = await _api.get(
      'api.php',
      query: <String, dynamic>{
        'get_search_category': '',
        'search': keyword,
      },
    );
    final categories = (response['categories'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => Category.fromJson(_normalizeCategoryJson(Map<String, dynamic>.from(item as Map))))
        .toList();
    return categories;
  }

  Future<Wallpaper?> fetchWallpaperDetail(String id) async {
    final response = await _api.get(
      'api.php',
      query: <String, dynamic>{
        'get_wallpaper_details': '',
        'id': id,
      },
    );
    final posts = (response['posts'] as List<dynamic>? ?? <dynamic>[])
        .map((item) => Wallpaper.fromJson(_normalizeWallpaperJson(Map<String, dynamic>.from(item as Map))))
        .toList();
    return posts.isEmpty ? null : posts.first;
  }

  Future<void> updateView(String id) async {
    await _api.post('api.php?update_view', data: <String, dynamic>{'image_id': id});
  }

  Future<void> updateDownload(String id) async {
    await _api.post('api.php?update_download', data: <String, dynamic>{'image_id': id});
  }

  int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  Map<String, dynamic> _normalizeWallpaperJson(Map<String, dynamic> json) {
    final type = (json['type']?.toString() ?? '').toLowerCase();
    final mime = (json['mime']?.toString() ?? '').toLowerCase();
    final imageUrl = json['image_url']?.toString() ?? '';
    final imageUpload = json['image_upload']?.toString() ?? '';
    final imageThumb = json['image_thumb']?.toString() ?? '';

    String resolveUploads(String value, {bool thumbs = false}) {
      if (value.isEmpty) {
        return '';
      }
      if (_isAbsoluteUrl(value)) {
        return value;
      }
      var normalized = value;
      if (normalized.startsWith('/')) {
        normalized = normalized.substring(1);
      }
      if (normalized.startsWith('upload/')) {
        return '${_api.rootBaseUrl}/$normalized';
      }
      final prefix = thumbs ? 'upload/thumbs/' : 'upload/';
      return '${_api.rootBaseUrl}/$prefix$normalized';
    }

    String resolvedThumb = '';
    if (imageThumb.isNotEmpty) {
      resolvedThumb = resolveUploads(imageThumb, thumbs: true);
    } else if (imageUpload.isNotEmpty) {
      resolvedThumb = resolveUploads(imageUpload, thumbs: true);
    }

    String resolvedFull = '';
    if (type == 'url') {
      if (mime.contains('octet-stream') || mime.contains('video/mp4')) {
        resolvedFull = resolveUploads(imageThumb, thumbs: true);
      } else if (imageUrl.isNotEmpty) {
        resolvedFull = _isAbsoluteUrl(imageUrl) ? imageUrl : resolveUploads(imageUrl);
      } else {
        resolvedFull = resolveUploads(imageUpload);
      }
    } else {
      if (mime.contains('webp') || mime.contains('bmp')) {
        resolvedFull = resolveUploads(imageUpload);
      } else if (mime.contains('octet-stream') || mime.contains('video/mp4')) {
        resolvedFull = resolveUploads(imageThumb, thumbs: true);
      } else if (imageThumb.isNotEmpty) {
        resolvedFull = resolveUploads(imageThumb, thumbs: true);
      } else if (imageUpload.isNotEmpty) {
        resolvedFull = resolveUploads(imageUpload, thumbs: true);
      }
    }

    json['image_thumb'] = resolvedThumb.isNotEmpty ? resolvedThumb : resolvedFull;
    json['image_url'] = resolvedFull.isNotEmpty ? resolvedFull : resolvedThumb;
    json['image_upload'] = resolveUploads(imageUpload);
    return json;
  }

  Map<String, dynamic> _normalizeCategoryJson(Map<String, dynamic> json) {
    final rawImage = json['category_image']?.toString() ?? '';
    if (rawImage.isEmpty || _isAbsoluteUrl(rawImage)) {
      return json;
    }
    json['category_image'] = '${_api.rootBaseUrl}/upload/category/$rawImage';
    return json;
  }

  bool _isAbsoluteUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }
}
