import 'dart:convert';

class Quote {
  final String id;
  final String text;
  final String author;
  final String? category;
  final bool isFavorite;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? favoriteDate;
  final String? source;
  final String? notes;

  Quote({
    required this.id,
    required this.text,
    required this.author,
    this.category,
    this.isFavorite = false,
    this.tags = const [],
    DateTime? createdAt,
    this.favoriteDate,
    this.source,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now();

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
    DateTime? favoriteDate,
    String? source,
    String? notes,
  }) {
    return Quote(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      favoriteDate: favoriteDate ?? this.favoriteDate,
      source: source ?? this.source,
      notes: notes ?? this.notes,
    );
  }

  // Generate a unique ID if not provided
  static String generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  // Helper method to toggle favorite
  Quote toggleFavorite() {
    return copyWith(
      isFavorite: !isFavorite,
      favoriteDate: !isFavorite ? DateTime.now() : null,
    );
  }

  // Add a tag
  Quote addTag(String tag) {
    final newTags = List<String>.from(tags)..add(tag);
    return copyWith(tags: newTags);
  }

  // Remove a tag
  Quote removeTag(String tag) {
    final newTags = List<String>.from(tags)..remove(tag);
    return copyWith(tags: newTags);
  }

  // Check if quote has a specific tag
  bool hasTag(String tag) {
    return tags.contains(tag);
  }

  // Format for display
  String get displayText => '"$text"';
  String get displayAuthor => '— $author';
  String get displayCategory => category != null ? '#$category' : '';

  // Get quote text with ellipsis for preview
  String get previewText {
    const maxLength = 50;
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'category': category,
      'isFavorite': isFavorite,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'favoriteDate': favoriteDate?.toIso8601String(),
      'source': source,
      'notes': notes,
    };
  }

  // Create from JSON
  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] ?? generateId(),
      text: json['text'] ?? '',
      author: json['author'] ?? '',
      category: json['category'],
      isFavorite: json['isFavorite'] ?? false,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      favoriteDate: json['favoriteDate'] != null
          ? DateTime.parse(json['favoriteDate'])
          : null,
      source: json['source'],
      notes: json['notes'],
    );
  }

  // Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // Create from JSON string
  factory Quote.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return Quote.fromJson(json);
  }

  // Equality check
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Quote && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  // String representation
  @override
  String toString() {
    return 'Quote(id: $id, text: "$previewText", author: $author, favorite: $isFavorite)';
  }

  // Check if quote is empty/invalid
  bool get isEmpty => id.isEmpty || text.isEmpty || author.isEmpty;
  bool get isNotEmpty => !isEmpty;

  // Age of the quote
  Duration get age => DateTime.now().difference(createdAt);

  // Formatted age string
  String get ageString {
    final days = age.inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    if (days < 30) return '${(days / 7).floor()} weeks ago';
    if (days < 365) return '${(days / 30).floor()} months ago';
    return '${(days / 365).floor()} years ago';
  }

  // Quote length category
  String get lengthCategory {
    final wordCount = text.split(' ').length;
    if (wordCount < 10) return 'Short';
    if (wordCount < 25) return 'Medium';
    return 'Long';
  }

  // Search helper
  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return text.toLowerCase().contains(lowerQuery) ||
        author.toLowerCase().contains(lowerQuery) ||
        (category?.toLowerCase().contains(lowerQuery) ?? false) ||
        tags.any((tag) => tag.toLowerCase().contains(lowerQuery)) ||
        (source?.toLowerCase().contains(lowerQuery) ?? false) ||
        (notes?.toLowerCase().contains(lowerQuery) ?? false);
  }

  // Share text format
  String get shareText {
    final buffer = StringBuffer('"$text"\n\n— $author');
    if (category != null) {
      buffer.write('\n\n#$category');
    }
    if (source != null) {
      buffer.write('\n\nSource: $source');
    }
    return buffer.toString();
  }

  // CSV format for export
  String toCsv() {
    final escapedText = text.replaceAll('"', '""');
    final escapedAuthor = author.replaceAll('"', '""');
    final escapedCategory = category?.replaceAll('"', '""') ?? '';
    final escapedSource = source?.replaceAll('"', '""') ?? '';
    final escapedNotes = notes?.replaceAll('"', '""') ?? '';
    final tagsString = tags.join(';');

    return '"$escapedText","$escapedAuthor","$escapedCategory","$isFavorite","$tagsString","$createdAt","$favoriteDate","$escapedSource","$escapedNotes"';
  }
}

// Helper extension for List<Quote>
extension QuoteListExtensions on List<Quote> {
  List<Quote> get favorites => where((quote) => quote.isFavorite).toList();
  List<Quote> get nonFavorites => where((quote) => !quote.isFavorite).toList();

  List<Quote> sortByDate({bool ascending = false}) {
    return List.from(this)..sort((a, b) {
      final comparison = a.createdAt.compareTo(b.createdAt);
      return ascending ? comparison : -comparison;
    });
  }

  List<Quote> sortByFavoriteDate({bool ascending = false}) {
    return favorites..sort((a, b) {
      final aDate = a.favoriteDate ?? DateTime(1970);
      final bDate = b.favoriteDate ?? DateTime(1970);
      final comparison = aDate.compareTo(bDate);
      return ascending ? comparison : -comparison;
    });
  }

  List<Quote> filterByCategory(String category) {
    if (category.isEmpty) return this;
    return where(
      (quote) => quote.category?.toLowerCase() == category.toLowerCase(),
    ).toList();
  }

  List<Quote> filterByTag(String tag) {
    if (tag.isEmpty) return this;
    return where((quote) => quote.hasTag(tag)).toList();
  }

  List<String> get allCategories {
    final categories = map(
      (quote) => quote.category,
    ).whereType<String>().toSet();
    return categories.toList()..sort();
  }

  List<String> get allTags {
    final tags = expand((quote) => quote.tags).toSet();
    return tags.toList()..sort();
  }
}
