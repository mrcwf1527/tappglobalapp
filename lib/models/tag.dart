// lib/models/tag.dart
// Data model for tags with id, name, color, and userId fields, including Firestore serialization methods.
class Tag {
  final String id;
  final String name;
  final String color;
  final String userId;

  Tag({
    required this.id,
    required this.name,
    required this.color,
    required this.userId,
  });

  factory Tag.fromMap(Map<String, dynamic> map, String id) {
    return Tag(
      id: id,
      name: map['name'] ?? '',
      color: map['color'] ?? '#000000',
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': color,
      'userId': userId,
    };
  }
}