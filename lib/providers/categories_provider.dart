import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/category.dart';
import 'app_config_provider.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  ref.watch(appConfigProvider); // ensure dependencies are ready
  final repository = ref.watch(wallpaperRepositoryProvider);
  return repository.fetchCategories();
});
