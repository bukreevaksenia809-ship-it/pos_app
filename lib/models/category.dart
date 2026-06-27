// lib/models/category.dart

class Category {
  final int id;
  final String name;
  final DateTime? createdAt;

  Category({
    required this.id,
    required this.name,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'created_at': createdAt?.toIso8601String(),
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'],
    name: map['name'] ?? '',
    createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
  );
}