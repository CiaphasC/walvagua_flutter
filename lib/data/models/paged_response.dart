class PagedResponse<T> {
  PagedResponse({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalItems,
  });

  final List<T> items;
  final int page;
  final int totalPages;
  final int totalItems;

  bool get hasMore => page < totalPages;
}
