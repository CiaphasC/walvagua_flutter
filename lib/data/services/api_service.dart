import 'package:dio/dio.dart';

class ApiService {
  ApiService(String baseUrl)
      : _rootBaseUrl = _normalizeRoot(baseUrl),
        _dio = Dio(
          BaseOptions(
            baseUrl: _normalizeBaseUrl(baseUrl),
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 20),
            headers: const {
              'Data-Agent': 'Material Wallpaper',
              'Cache-Control': 'max-age=0',
            },
          ),
        );

  final Dio _dio;
  final String _rootBaseUrl;

  String get rootBaseUrl => _rootBaseUrl;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    final response = await _dio.get<Map<String, dynamic>>(path, queryParameters: query);
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    final response = await _dio.post<Map<String, dynamic>>(path, data: FormData.fromMap(data ?? <String, dynamic>{}));
    return response.data ?? <String, dynamic>{};
  }

  ApiService copyWithBaseUrl(String baseUrl) {
    return ApiService(baseUrl);
  }

  static String _normalizeBaseUrl(String baseUrl) {
    var normalized = _normalizeRoot(baseUrl);
    if (!normalized.endsWith('/api/v1')) {
      normalized = '$normalized/api/v1';
    }
    return '$normalized/';
  }

  static String _normalizeRoot(String baseUrl) {
    var normalized = baseUrl.trim();
    if (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}
