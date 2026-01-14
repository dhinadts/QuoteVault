import 'dart:convert';

class Quote {
  final String id;
  final String text;
  final String author;
  final String? category;
  final bool isFavorite;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? favoriteDate;
  final String? source;
  final String? notes;
  final String? userId;

  Quote({
    required this.id,
    required this.text,
    required this.author,
    this.category,
    this.isFavorite = false,
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.favoriteDate,
    this.source,
    this.notes,
    this.userId,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Quote.empty() {
    return Quote(id: '', text: '', author: '');
  }

  Quote copyWith({
    String? id,
    String? text,
    String? author,
    String? category,
    bool? isFavorite,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? favoriteDate,
    String? source,
    String? notes,
    String? userId,
  }) {
    return Quote(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      favoriteDate: favoriteDate ?? this.favoriteDate,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
    );
  }

  // Helper method to toggle favorite
  Quote toggleFavorite() {
    return copyWith(
      isFavorite: !isFavorite,
      favoriteDate: !isFavorite ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
  }

  // Add tags (optional - you can add this column to Supabase later)
  Quote addTags(List<String> newTags) {
    final allTags = {...tags, ...newTags}.toList();
    return copyWith(tags: allTags);
  }

  // Convert to JSON for Supabase (matches your table columns)
  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'category': category,
      'created_at': createdAt.toUtc().toIso8601String(),
      'user_id': userId,
      // Add these columns to your Supabase table:
      'is_favorite': isFavorite,
      'tags': tags.isNotEmpty ? tags : null,
      'favorite_date': favoriteDate?.toUtc().toIso8601String(),
      'source': source,
      'notes': notes,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  // Create from Supabase JSON
  factory Quote.fromSupabaseJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      category: json['category']?.toString(),
      // These need to be added to your Supabase table:
      isFavorite: json['is_favorite'] ?? false,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at']).toLocal()
          : DateTime.now(),
      favoriteDate: json['favorite_date'] != null
          ? DateTime.parse(json['favorite_date']).toLocal()
          : null,
      source: json['source']?.toString(),
      notes: json['notes']?.toString(),
      userId: json['user_id']?.toString(),
    );
  }

  // For backward compatibility
  Map<String, dynamic> toJson() => toSupabaseJson();
  factory Quote.fromJson(Map<String, dynamic> json) =>
      Quote.fromSupabaseJson(json);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Quote && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Quote(id: $id, text: "$text", author: $author, favorite: $isFavorite)';
  }
}
