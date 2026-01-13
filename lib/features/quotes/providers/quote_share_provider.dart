import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'quote_card_template.dart';

/// A service for generating, sharing, and saving quote cards
class QuoteShareService {
  static const _defaultQuoteMarkSpacing = 40.0;
  static const _defaultWatermarkOpacity = 0.3;
  static const _defaultAppBrandingOpacity = 0.5;
  static const _appBrandingText = 'Made with QuoteVault';
  static const _quoteFilePrefix = 'quote_';

  /// Generates a quote card image with optional watermark and branding
  Future<Uint8List?> generateQuoteCard({
    required String text,
    required String author,
    required String? category,
    required QuoteCardTemplate template,
    required Size size,
    String? watermark,
    double watermarkOpacity = _defaultWatermarkOpacity,
    bool addAppBranding = false,
  }) async {
    try {
      // Validate input
      if (text.isEmpty || author.isEmpty) {
        throw ArgumentError('Text and author are required');
      }

      // Generate base image
      var imageBytes = await _generateBaseImage(
        text: text,
        author: author,
        category: category,
        template: template,
        size: size,
      );

      // Apply watermark if provided
      if (watermark != null && watermark.isNotEmpty) {
        imageBytes = await _applyWatermark(
          imageBytes,
          watermark,
          watermarkOpacity,
        );
      }

      // Apply app branding if requested
      if (addAppBranding) {
        imageBytes = await _applyAppBranding(imageBytes);
      }

      return imageBytes;
    } catch (e, stackTrace) {
      debugPrint('Error generating quote card: $e\n$stackTrace');
      return null;
    }
  }

  /// Shares quote as plain text
  Future<void> shareAsText({
    required String text,
    required String author,
    String? category,
  }) async {
    try {
      final shareText = _buildShareText(text, author, category);
      await Share.share(shareText, subject: 'Quote by $author');
    } catch (e, stackTrace) {
      debugPrint('Error sharing text: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Shares quote card as an image
  Future<void> shareQuoteCard({
    required Uint8List imageBytes,
    String? fileName,
    String? shareText,
  }) async {
    try {
      // Create temporary file
      final tempFile = await _createTempFile(
        imageBytes,
        fileName:
            fileName ??
            '${_quoteFilePrefix}${DateTime.now().millisecondsSinceEpoch}.png',
      );

      // Share the file
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: shareText ?? 'Check out this quote!',
        subject: 'Quote Card',
      );

      // Schedule cleanup
      _scheduleFileCleanup(tempFile);
    } catch (e, stackTrace) {
      debugPrint('Error sharing quote card: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Saves quote card to app's local documents directory
  Future<File?> saveQuoteCardLocally({
    required Uint8List imageBytes,
    String? fileName,
    Directory? targetDirectory,
  }) async {
    try {
      final directory =
          targetDirectory ?? await getApplicationDocumentsDirectory();
      final name = fileName ?? _generateFileName();
      final file = File('${directory.path}/$name');

      // Ensure directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Write the file
      await file.writeAsBytes(imageBytes);
      return file;
    } catch (e, stackTrace) {
      debugPrint('Error saving quote card locally: $e\n$stackTrace');
      return null;
    }
  }

  /// Gets all saved quote cards from local directory
  Future<List<File>> getSavedQuoteCards({Directory? directory}) async {
    try {
      final targetDir = directory ?? await getApplicationDocumentsDirectory();
      final files = await targetDir.list().toList();

      return files
          .whereType<File>()
          .where((file) => file.path.endsWith('.png'))
          .where((file) => file.path.contains(_quoteFilePrefix))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('Error getting saved quote cards: $e\n$stackTrace');
      return [];
    }
  }

  /// Deletes a saved quote card
  Future<bool> deleteQuoteCard(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e, stackTrace) {
      debugPrint('Error deleting quote card: $e\n$stackTrace');
      return false;
    }
  }

  /// Deletes all saved quote cards
  Future<int> deleteAllQuoteCards({Directory? directory}) async {
    try {
      final quoteCards = await getSavedQuoteCards(directory: directory);
      int deletedCount = 0;

      for (final file in quoteCards) {
        if (await deleteQuoteCard(file)) {
          deletedCount++;
        }
      }

      return deletedCount;
    } catch (e, stackTrace) {
      debugPrint('Error deleting all quote cards: $e\n$stackTrace');
      return 0;
    }
  }

  // Private helper methods

  Future<Uint8List> _generateBaseImage({
    required String text,
    required String author,
    required String? category,
    required QuoteCardTemplate template,
    required Size size,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw background
    _drawBackground(canvas, size, template);

    // Draw pattern if exists
    template.pattern?.call(canvas, size);

    // Draw decorative elements
    for (final element in template.decorativeElements) {
      element(canvas, size);
    }

    // Draw quote content
    _drawQuoteContent(
      canvas: canvas,
      text: text,
      author: author,
      category: category,
      template: template,
      size: size,
    );

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  void _drawBackground(Canvas canvas, Size size, QuoteCardTemplate template) {
    // Solid background
    final backgroundPaint = Paint()
      ..color = template.backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Gradient overlay if specified
    if (template.gradientColors != null &&
        template.gradientColors!.length >= 2) {
      final gradient = LinearGradient(
        colors: template.gradientColors!,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      final gradientPaint = Paint()
        ..shader = gradient
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.multiply;

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        gradientPaint,
      );
    }
  }

  void _drawQuoteContent({
    required Canvas canvas,
    required String text,
    required String author,
    required String? category,
    required QuoteCardTemplate template,
    required Size size,
  }) {
    // Quote marks
    final quoteMarkStyle = TextStyle(
      fontSize: template.textSize * 1.5,
      fontWeight: FontWeight.w700,
      color: template.accentColor,
      fontFamily: 'Georgia',
    );

    // Opening quote mark
    final openingQuote = TextPainter(
      text: TextSpan(text: '“', style: quoteMarkStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    openingQuote.paint(
      canvas,
      Offset(template.padding.left + 5, template.padding.top - 10),
    );

    // Main quote text
    final textStyle = TextStyle(
      fontSize: template.textSize,
      fontWeight: FontWeight.w600,
      color: template.textColor,
      fontFamily: 'Roboto',
      height: 1.5,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: 6,
      ellipsis: '...',
    );

    textPainter.layout(
      maxWidth:
          size.width - template.padding.horizontal - _defaultQuoteMarkSpacing,
    );

    final textX = template.padding.left + _defaultQuoteMarkSpacing;
    final textY = template.padding.top;
    textPainter.paint(canvas, Offset(textX, textY));

    // Author text
    final authorStyle = TextStyle(
      fontSize: template.authorSize,
      fontWeight: FontWeight.w500,
      color: template.authorColor,
      fontStyle: FontStyle.italic,
      fontFamily: 'Roboto',
    );

    final authorPainter = TextPainter(
      text: TextSpan(text: '— $author', style: authorStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final authorX = size.width - authorPainter.width - template.padding.right;
    final authorY =
        size.height -
        template.padding.bottom -
        authorPainter.height -
        (category != null ? 25 : 0);
    authorPainter.paint(canvas, Offset(authorX, authorY));

    // Category text (if provided)
    if (category != null && category.isNotEmpty) {
      final categoryStyle = TextStyle(
        fontSize: template.categorySize,
        fontWeight: FontWeight.w400,
        color: template.categoryColor,
        fontFamily: 'Roboto',
      );

      final categoryPainter = TextPainter(
        text: TextSpan(text: '#$category', style: categoryStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final categoryX =
          size.width - categoryPainter.width - template.padding.right;
      final categoryY =
          size.height - template.padding.bottom - categoryPainter.height;
      categoryPainter.paint(canvas, Offset(categoryX, categoryY));
    }

    // Closing quote mark
    final closingQuote = TextPainter(
      text: TextSpan(text: '”', style: quoteMarkStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    closingQuote.paint(
      canvas,
      Offset(
        size.width - template.padding.right - closingQuote.width - 5,
        textY + textPainter.height - closingQuote.height + 10,
      ),
    );
  }

  Future<Uint8List> _applyWatermark(
    Uint8List imageBytes,
    String watermark,
    double opacity,
  ) async {
    try {
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // Draw original image
      canvas.drawImage(frame.image, Offset.zero, Paint());

      // Draw watermark
      final textStyle = ui.TextStyle(
        color: Colors.white.withOpacity(opacity.clamp(0.0, 1.0)),
        fontSize: 16,
        fontFamily: 'Roboto',
      );

      final paragraphBuilder =
          ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
            ..pushStyle(textStyle)
            ..addText(watermark);

      final paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: 300));

      canvas.drawParagraph(
        paragraph,
        Offset(20, frame.image.height - paragraph.height - 20),
      );

      final picture = recorder.endRecording();
      final watermarkedImage = await picture.toImage(
        frame.image.width,
        frame.image.height,
      );

      final byteData = await watermarkedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      return byteData!.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error applying watermark: $e');
      return imageBytes;
    }
  }

  Future<Uint8List> _applyAppBranding(Uint8List imageBytes) async {
    return _applyWatermark(
      imageBytes,
      _appBrandingText,
      _defaultAppBrandingOpacity,
    );
  }

  Future<File> _createTempFile(
    Uint8List bytes, {
    required String fileName,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  void _scheduleFileCleanup(File file) {
    Future.delayed(const Duration(minutes: 5), () {
      try {
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        debugPrint('Error cleaning up temp file: $e');
      }
    });
  }

  String _buildShareText(String text, String author, String? category) {
    final buffer = StringBuffer('"$text"\n\n— $author');
    if (category != null && category.isNotEmpty) {
      buffer.write('\n\n#$category');
    }
    return buffer.toString();
  }

  String _generateFileName() {
    return '${_quoteFilePrefix}${DateTime.now().millisecondsSinceEpoch}.png';
  }
}

/// Utility class for platform-specific operations
class QuoteShareUtils {
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;
  static bool get isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  static bool get isWeb => kIsWeb;

  /// Gets the appropriate directory for saving quote cards based on platform
  static Future<Directory?> getSaveDirectory({
    bool useExternalStorage = false,
  }) async {
    if (isWeb) {
      return null; // Web doesn't have direct file system access
    }

    try {
      if (isMobile && useExternalStorage) {
        return await getExternalStorageDirectory();
      } else if (isDesktop) {
        return await getDownloadsDirectory();
      } else {
        return await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      debugPrint('Error getting save directory: $e');
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Gets the available storage space in bytes
  static Future<int?> getAvailableStorage() async {
    if (isWeb) return null;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final stat = directory.statSync();
      return stat.size;
    } catch (e) {
      debugPrint('Error getting available storage: $e');
      return null;
    }
  }

  /// Formats file size for display
  static String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }
}

/// Extension methods for QuoteShareService
extension QuoteShareServiceExtensions on QuoteShareService {
  /// Generates and shares a quote card in one operation
  Future<void> generateAndShareQuote({
    required String text,
    required String author,
    required String? category,
    required QuoteCardTemplate template,
    required Size size,
    String? watermark,
    bool addAppBranding = false,
    String? shareMessage,
  }) async {
    final imageBytes = await generateQuoteCard(
      text: text,
      author: author,
      category: category,
      template: template,
      size: size,
      watermark: watermark,
      addAppBranding: addAppBranding,
    );

    if (imageBytes != null) {
      await shareQuoteCard(imageBytes: imageBytes, shareText: shareMessage);
    } else {
      await shareAsText(text: text, author: author, category: category);
    }
  }

  /// Saves quote card and returns the saved file path
  Future<String?> saveAndGetPath({
    required Uint8List imageBytes,
    String? fileName,
  }) async {
    final file = await saveQuoteCardLocally(
      imageBytes: imageBytes,
      fileName: fileName,
    );
    return file?.path;
  }
}
