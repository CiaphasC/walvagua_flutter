class MenuTab {
  MenuTab({
    required this.id,
    required this.title,
    required this.order,
    required this.filter,
    required this.category,
  });

  final String id;
  final String title;
  final String order;
  final String filter;
  final String category;

  factory MenuTab.fromJson(Map<String, dynamic> json) {
    return MenuTab(
      id: json['menu_id']?.toString() ?? '',
      title: json['menu_title']?.toString() ?? '',
      order: json['menu_order']?.toString() ?? '',
      filter: json['menu_filter']?.toString() ?? '',
      category: json['menu_category']?.toString() ?? '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menu_id': id,
      'menu_title': title,
      'menu_order': order,
      'menu_filter': filter,
      'menu_category': category,
    };
  }
}
