import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// Quote card template with different styles
class QuoteCardTemplate {
  final String name;
  final String id;
  final Color backgroundColor;
  final Color textColor;
  final Color authorColor;
  final Color categoryColor;
  final Color accentColor;
  final double textSize;
  final double authorSize;
  final double categorySize;
  final EdgeInsets padding;
  final List<Color>? gradientColors;
  final List<Function(ui.Canvas, Size)> decorativeElements;
  final Function(ui.Canvas, Size)? pattern;

  QuoteCardTemplate({
    required this.name,
    required this.id,
    required this.backgroundColor,
    required this.textColor,
    required this.authorColor,
    required this.categoryColor,
    required this.accentColor,
    this.textSize = 24.0,
    this.authorSize = 18.0,
    this.categorySize = 14.0,
    this.padding = const EdgeInsets.all(40.0),
    this.gradientColors,
    this.decorativeElements = const [],
    this.pattern,
  });
}

// Pre-defined templates
class QuoteCardTemplates {
  static final List<QuoteCardTemplate> templates = [
    // Template 1: Minimal
    QuoteCardTemplate(
      name: 'Minimal',
      id: 'minimal',
      backgroundColor: Colors.white,
      textColor: Colors.black87,
      authorColor: Colors.black54,
      categoryColor: Colors.blueGrey[300]!,
      accentColor: Colors.black26,
      textSize: 22.0,
      authorSize: 16.0,
      padding: const EdgeInsets.all(50.0),
      decorativeElements: [
        (canvas, size) {
          final paint = Paint()
            ..color = Colors.black12
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke;

          canvas.drawRect(
            Rect.fromLTWH(30, 30, size.width - 60, size.height - 60),
            paint,
          );
        },
      ],
    ),

    // Template 2: Gradient
    QuoteCardTemplate(
      name: 'Gradient',
      id: 'gradient',
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      authorColor: Colors.white70,
      categoryColor: Colors.white60,
      accentColor: Colors.white,
      textSize: 26.0,
      authorSize: 20.0,
      padding: const EdgeInsets.all(40.0),
      gradientColors: [
        Colors.blue.shade800,
        Colors.purple.shade600,
        Colors.pink.shade600,
      ],
      decorativeElements: [
        (canvas, size) {
          // Add some sparkles
          final paint = Paint()
            ..color = Colors.white.withOpacity(0.3)
            ..style = PaintingStyle.fill;

          for (int i = 0; i < 20; i++) {
            final x = size.width * 0.2 + (size.width * 0.6 * i / 20);
            final y = size.height * 0.3 + (size.height * 0.4 * (i % 5) / 5);
            canvas.drawCircle(Offset(x, y), 2, paint);
          }
        },
      ],
    ),

    // Template 3: Dark Elegant
    QuoteCardTemplate(
      name: 'Dark Elegant',
      id: 'dark_elegant',
      backgroundColor: Colors.grey[900]!,
      textColor: Colors.white,
      authorColor: Colors.grey[300]!,
      categoryColor: Colors.amber[300]!,
      accentColor: Colors.amber,
      textSize: 24.0,
      authorSize: 18.0,
      padding: const EdgeInsets.all(45.0),
      pattern: (canvas, size) {
        // Geometric pattern
        final paint = Paint()
          ..color = Colors.white.withOpacity(0.05)
          ..style = PaintingStyle.fill;

        final patternPaint = Paint()
          ..color = Colors.amber.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        // Draw diagonal lines
        for (double i = 0; i < size.width * 2; i += 20) {
          canvas.drawLine(Offset(i, 0), Offset(0, i), patternPaint);
        }

        // Draw accent circles
        canvas.drawCircle(
          Offset(size.width * 0.2, size.height * 0.2),
          60,
          paint,
        );

        canvas.drawCircle(
          Offset(size.width * 0.8, size.height * 0.8),
          80,
          paint,
        );
      },
      decorativeElements: [
        (canvas, size) {
          // Gold border
          final borderPaint = Paint()
            ..color = Colors.amber
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke;

          canvas.drawRect(
            Rect.fromLTWH(20, 20, size.width - 40, size.height - 40),
            borderPaint,
          );
        },
      ],
    ),

    // Template 4: Modern
    QuoteCardTemplate(
      name: 'Modern',
      id: 'modern',
      backgroundColor: Colors.white,
      textColor: Colors.grey[900]!,
      authorColor: Colors.blue[600]!,
      categoryColor: Colors.grey[600]!,
      accentColor: Colors.blue,
      textSize: 28.0,
      authorSize: 22.0,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      decorativeElements: [
        (canvas, size) {
          // Modern accent shapes
          final accentPaint = Paint()
            ..color = Colors.blue.withOpacity(0.1)
            ..style = PaintingStyle.fill;

          // Top-left triangle
          final path = ui.Path()
            ..moveTo(0, 0)
            ..lineTo(150, 0)
            ..lineTo(0, 150)
            ..close();
          canvas.drawPath(path, accentPaint);

          // Bottom-right circle
          canvas.drawCircle(Offset(size.width, size.height), 100, accentPaint);
        },
      ],
    ),

    // Template 5: Vintage
    QuoteCardTemplate(
      name: 'Vintage',
      id: 'vintage',
      backgroundColor: Color(0xFFF5E9D9),
      textColor: Color(0xFF3E2723),
      authorColor: Color(0xFF5D4037),
      categoryColor: Color(0xFF795548),
      accentColor: Color(0xFF8D6E63),
      textSize: 26.0,
      authorSize: 20.0,
      padding: const EdgeInsets.all(50.0),
      pattern: (canvas, size) {
        // Vintage paper texture
        final texturePaint = Paint()
          ..color = Color(0xFFD7CCC8).withOpacity(0.1);

        for (double i = 0; i < size.width; i += 3) {
          for (double j = 0; j < size.height; j += 3) {
            if ((i + j) % 6 == 0) {
              canvas.drawCircle(Offset(i, j), 0.5, texturePaint);
            }
          }
        }

        // Coffee stain effect
        final stainPaint = Paint()..color = Color(0xFFBCAAA4).withOpacity(0.05);

        canvas.drawCircle(
          Offset(size.width * 0.3, size.height * 0.7),
          50,
          stainPaint,
        );

        canvas.drawCircle(
          Offset(size.width * 0.8, size.height * 0.3),
          40,
          stainPaint,
        );
      },
      decorativeElements: [
        (canvas, size) {
          // Ornate border
          final borderPaint = Paint()
            ..color = Color(0xFF8D6E63)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;

          final innerBorderPaint = Paint()
            ..color = Color(0xFF8D6E63).withOpacity(0.3)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke;

          canvas.drawRect(
            Rect.fromLTWH(15, 15, size.width - 30, size.height - 30),
            borderPaint,
          );

          canvas.drawRect(
            Rect.fromLTWH(25, 25, size.width - 50, size.height - 50),
            innerBorderPaint,
          );
        },
      ],
    ),

    // Template 6: Professional
    QuoteCardTemplate(
      name: 'Professional',
      id: 'professional',
      backgroundColor: Colors.white,
      textColor: Colors.black87,
      authorColor: Colors.blueGrey[800]!,
      categoryColor: Colors.blue[700]!,
      accentColor: Colors.blue[600]!,
      textSize: 26.0,
      authorSize: 20.0,
      padding: const EdgeInsets.all(60.0),
      decorativeElements: [
        (canvas, size) {
          // Thin border
          final borderPaint = Paint()
            ..color = Colors.blue[100]!
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;

          canvas.drawRect(
            Rect.fromLTWH(30, 30, size.width - 60, size.height - 60),
            borderPaint,
          );

          // Corner accents
          final accentPaint = Paint()
            ..color = Colors.blue[600]!
            ..strokeWidth = 4
            ..style = PaintingStyle.stroke;

          const cornerLength = 40.0;

          // Top-left corner
          canvas.drawLine(
            Offset(30, 30),
            Offset(30 + cornerLength, 30),
            accentPaint,
          );
          canvas.drawLine(
            Offset(30, 30),
            Offset(30, 30 + cornerLength),
            accentPaint,
          );

          // Top-right corner
          canvas.drawLine(
            Offset(size.width - 30, 30),
            Offset(size.width - 30 - cornerLength, 30),
            accentPaint,
          );
          canvas.drawLine(
            Offset(size.width - 30, 30),
            Offset(size.width - 30, 30 + cornerLength),
            accentPaint,
          );

          // Bottom-left corner
          canvas.drawLine(
            Offset(30, size.height - 30),
            Offset(30 + cornerLength, size.height - 30),
            accentPaint,
          );
          canvas.drawLine(
            Offset(30, size.height - 30),
            Offset(30, size.height - 30 - cornerLength),
            accentPaint,
          );

          // Bottom-right corner
          canvas.drawLine(
            Offset(size.width - 30, size.height - 30),
            Offset(size.width - 30 - cornerLength, size.height - 30),
            accentPaint,
          );
          canvas.drawLine(
            Offset(size.width - 30, size.height - 30),
            Offset(size.width - 30, size.height - 30 - cornerLength),
            accentPaint,
          );
        },
      ],
    ),

    // Template 7: Vibrant
    QuoteCardTemplate(
      name: 'Vibrant',
      id: 'vibrant',
      backgroundColor: Colors.orange[50]!,
      textColor: Colors.deepPurple[900]!,
      authorColor: Colors.pink[700]!,
      categoryColor: Colors.teal[700]!,
      accentColor: Colors.orange[600]!,
      textSize: 28.0,
      authorSize: 22.0,
      padding: const EdgeInsets.all(50.0),
      gradientColors: [
        Colors.orange[50]!,
        Colors.yellow[50]!,
        Colors.pink[50]!,
      ],
      decorativeElements: [
        (canvas, size) {
          // Abstract shapes
          final shapes = [
            (Paint()
              ..color = Colors.orange.withOpacity(0.2)
              ..style = PaintingStyle.fill),
            (Paint()
              ..color = Colors.pink.withOpacity(0.2)
              ..style = PaintingStyle.fill),
            (Paint()
              ..color = Colors.teal.withOpacity(0.2)
              ..style = PaintingStyle.fill),
          ];

          // Draw random circles
          final random = Random();
          for (int i = 0; i < 15; i++) {
            final paint = shapes[i % shapes.length];
            final radius = random.nextDouble() * 60 + 20;
            final x = random.nextDouble() * size.width;
            final y = random.nextDouble() * size.height;
            canvas.drawCircle(Offset(x, y), radius, paint);
          }
        },
      ],
    ),

    // Template 8: Monochrome
    QuoteCardTemplate(
      name: 'Monochrome',
      id: 'monochrome',
      backgroundColor: Colors.grey[900]!,
      textColor: Colors.grey[100]!,
      authorColor: Colors.grey[300]!,
      categoryColor: Colors.grey[400]!,
      accentColor: Colors.grey[500]!,
      textSize: 24.0,
      authorSize: 18.0,
      padding: const EdgeInsets.all(55.0),
      pattern: (canvas, size) {
        // Grid pattern
        final gridPaint = Paint()
          ..color = Colors.white.withOpacity(0.05)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;

        // Vertical lines
        for (double x = 0; x < size.width; x += 50) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
        }

        // Horizontal lines
        for (double y = 0; y < size.height; y += 50) {
          canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
        }

        // Dot pattern
        final dotPaint = Paint()
          ..color = Colors.white.withOpacity(0.1)
          ..style = PaintingStyle.fill;

        for (double x = 25; x < size.width; x += 50) {
          for (double y = 25; y < size.height; y += 50) {
            canvas.drawCircle(Offset(x, y), 2, dotPaint);
          }
        }
      },
      decorativeElements: [
        (canvas, size) {
          // Thin frame
          final framePaint = Paint()
            ..color = Colors.white.withOpacity(0.2)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke;

          canvas.drawRect(
            Rect.fromLTWH(20, 20, size.width - 40, size.height - 40),
            framePaint,
          );
        },
      ],
    ),
  ];

  // Helper to get template by ID
  static QuoteCardTemplate? getTemplateById(String id) {
    return templates.firstWhereOrNull((template) => template.id == id);
  }
}

// Extension for firstWhereOrNull
extension FirstWhereOrNullExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
