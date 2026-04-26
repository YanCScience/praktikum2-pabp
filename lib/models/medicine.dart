class Medicine {
  final int id;
  final String name;
  final String category;
  final int stock;
  final double price;

  Medicine({
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.price,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      stock: json['stock'],
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'stock': stock,
      'price': price,
    };
  }
}