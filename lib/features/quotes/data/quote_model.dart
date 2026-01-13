class Quote {
  final String id; // Change from int to String (UUID)
  final String text;
  final String author;
  final String? category; // Make category nullable

  Quote({
    required this.id,
    required this.text,
    required this.author,
    this.category,
  });

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
    id: json['id'] as String,
    text: json['text'] as String,
    author: json['author'] as String,
    category: json['category'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'author': author,
    'category': category,
  };
}
