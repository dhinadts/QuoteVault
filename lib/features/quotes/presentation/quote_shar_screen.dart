import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotevault/features/quotes/data/quote_model.dart';
import 'package:quotevault/features/quotes/providers/quote_card_template.dart';
import 'package:quotevault/features/quotes/providers/quote_provider.dart';
// import 'quote_share_service.dart';
// import 'quote_card_template.dart';
// import 'share_providers.dart';

class QuoteShareScreen extends ConsumerStatefulWidget {
  final Quote quote;

  const QuoteShareScreen({super.key, required this.quote});

  @override
  ConsumerState<QuoteShareScreen> createState() => _QuoteShareScreenState();
}

class _QuoteShareScreenState extends ConsumerState<QuoteShareScreen> {
  QuoteCardTemplate? _selectedTemplate;
  bool _isGenerating = false;
  Uint8List? _generatedImage;
  bool _showAdvancedSettings = false;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = ref.read(selectedTemplateProvider);
  }

  Future<void> _generateImage() async {
    if (_selectedTemplate == null) return;

    setState(() => _isGenerating = true);

    try {
      final shareService = ref.read(quoteShareServiceProvider);
      final shareSettings = ref.read(shareSettingsProvider);

      final imageBytes = await shareService.generateQuoteCard(
        text: widget.quote.text,
        author: widget.quote.author,
        category: shareSettings.includeCategory ? widget.quote.category : null,
        template: _selectedTemplate!,
        size: const Size(1200, 1200), // High resolution for good quality
      );

      setState(() {
        _generatedImage = imageBytes;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      _showErrorSnackBar('Failed to generate image: $e');
    }
  }

  Future<void> _shareAsText() async {
    try {
      final shareService = ref.read(quoteShareServiceProvider);
      final shareSettings = ref.read(shareSettingsProvider);

      await shareService.shareAsText(
        text: widget.quote.text,
        author: widget.quote.author,
        category: shareSettings.includeCategory ? widget.quote.category : null,
      );
    } catch (e) {
      _showErrorSnackBar('Failed to share as text: $e');
    }
  }

  Future<void> _shareImage() async {
    if (_generatedImage == null) {
      await _generateImage();
      if (_generatedImage == null) return;
    }

    try {
      final shareService = ref.read(quoteShareServiceProvider);
      // await shareService.shareQuoteCard(_generatedImage!);
      // Replace gallery saving with sharing (users can save from share sheet)
      await shareService.shareQuoteCard(
        imageBytes: _generatedImage!,
        fileName: 'quote_${widget.quote.author.replaceAll(' ', '_')}.png',
        shareText: 'Check out this quote by ${widget.quote.author}!',
      );
    } catch (e) {
      _showErrorSnackBar('Failed to share image: $e');
    }
  }

  Future<void> _saveToGallery() async {
    if (_generatedImage == null) {
      await _generateImage();
      if (_generatedImage == null) return;
    }

    try {
      final shareService = ref.read(quoteShareServiceProvider);
      final success = await shareService.saveQuoteCardLocally(
        imageBytes: _generatedImage!,
        fileName: 'quote_${widget.quote.author.replaceAll(' ', '_')}.png',
      );

      if (success != null) {
        _showSuccessSnackBar('Saved to gallery!');
      } else {
        _showErrorSnackBar('Failed to save. Check permissions.');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save image: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shareSettings = ref.watch(shareSettingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Quote'),
        actions: [
          if (_generatedImage != null)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: _saveToGallery,
              tooltip: 'Save to Gallery',
            ),
          if (_generatedImage != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: _shareImage,
              tooltip: 'Share Image',
            ),
        ],
      ),
      body: Column(
        children: [
          // Preview Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildPreviewSection(),
            ),
          ),

          // Controls Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: _buildControlsSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Preview image
            if (_generatedImage != null)
              Image.memory(_generatedImage!, fit: BoxFit.cover)
            else
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_rounded,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select a template and tap "Generate"',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

            // Loading overlay
            if (_isGenerating)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Generating image...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

            // Info overlay
            if (_generatedImage != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Template: ${_selectedTemplate?.name ?? "Not selected"}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Size: 1200×1200 px',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsSection() {
    final shareSettings = ref.watch(shareSettingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Template Selection
        const Text(
          'Card Style',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 12),

        SizedBox(
          height: 70,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: QuoteCardTemplates.templates.map((template) {
              final isSelected = _selectedTemplate?.id == template.id;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedTemplate = template);
                  ref.read(selectedTemplateProvider.notifier).state = template;
                  _generatedImage = null;
                },
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: template.backgroundColor,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        template.name,
                        style: TextStyle(
                          color: template.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${template.textSize.toInt()}px',
                        style: TextStyle(
                          color: template.textColor.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 20),

        // Advanced Settings Toggle
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GestureDetector(
                onTap: () => setState(
                  () => _showAdvancedSettings = !_showAdvancedSettings,
                ),
                child: Row(
                  children: [
                    Text(
                      'Advanced Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _showAdvancedSettings
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
          ],
        ),

        // Advanced Settings Panel
        if (_showAdvancedSettings)
          Column(
            children: [
              const SizedBox(height: 16),

              // Include Category
              _buildSettingSwitch(
                icon: Icons.category_rounded,
                title: 'Include Category',
                value: shareSettings.includeCategory,
                onChanged: () {
                  ref
                      .read(shareSettingsProvider.notifier)
                      .toggleIncludeCategory();
                  _generatedImage = null;
                },
              ),

              // Image Quality
              _buildSettingSlider(
                icon: Icons.high_quality_rounded,
                title: 'Image Quality',
                value: shareSettings.imageQuality,
                onChanged: (value) {
                  ref
                      .read(shareSettingsProvider.notifier)
                      .setImageQuality(value);
                  _generatedImage = null;
                },
              ),

              // Template Description
              if (_selectedTemplate != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Template "${_selectedTemplate!.name}" uses ${_selectedTemplate!.gradientColors != null ? 'gradient' : 'solid'} background',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

        const SizedBox(height: 24),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.text_fields_rounded),
                label: const Text('Share as Text'),
                onPressed: _shareAsText,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.image_rounded),
                label: Text(
                  _generatedImage == null ? 'Generate Image' : 'Regenerate',
                ),
                onPressed: _isGenerating ? null : _generateImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),

        if (_generatedImage != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Share Image'),
                  onPressed: _shareImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSettingSwitch({
    required IconData icon,
    required String title,
    required bool value,
    required VoidCallback onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: value,
            onChanged: (val) => onChanged(),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSlider({
    required IconData icon,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            onChanged: onChanged,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            label: '${(value * 100).toInt()}%',
          ),
        ],
      ),
    );
  }
}
