import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quotevault/core/providers/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../../core/providers/supabase_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final nameCtrl = TextEditingController();
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;
  bool _isEditingName = false;
  late FocusNode _nameFocusNode;
  bool _bucketChecked = false;

  @override
  void initState() {
    super.initState();
    _nameFocusNode = FocusNode();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _checkAvatarBucket() async {
    if (_bucketChecked) return true;

    try {
      final supabase = ref.read(supabaseProvider);
      try {
        await supabase.storage.from('avatars').list();
        debugPrint('✅ Avatars bucket exists');
        _bucketChecked = true;
        return true;
      } catch (e) {
        debugPrint('⚠️ Avatars bucket not found or inaccessible: $e');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error checking bucket: $e');
      return false;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    }
  }

  Future<String?> _uploadAvatar(File imageFile) async {
    final bucketExists = await _checkAvatarBucket();
    if (!bucketExists) {
      _showSnackBar('Please set up storage bucket first');
      return null;
    }

    try {
      final supabase = ref.read(supabaseProvider);
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final fileName =
          'avatar_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileBytes = await imageFile.readAsBytes();

      debugPrint('📤 Uploading avatar: $fileName');

      try {
        await supabase.storage
            .from('avatars')
            .uploadBinary(
              fileName,
              fileBytes,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );

        final publicUrl = supabase.storage
            .from('avatars')
            .getPublicUrl(fileName);

        final urlWithCacheBuster =
            '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

        debugPrint('✅ Avatar uploaded: $urlWithCacheBuster');

        return urlWithCacheBuster;
      } catch (uploadError) {
        debugPrint('❌ Upload error: $uploadError');
        _showSnackBar('Upload failed. Check storage permissions.');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      _showSnackBar('Error: ${e.toString()}');
      return null;
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isUploading = true);

    try {
      final supabase = ref.read(supabaseProvider);
      final user = supabase.auth.currentUser;
      if (user == null) return;

      String? avatarUrl;

      if (_selectedImage != null) {
        final uploadedUrl = await _uploadAvatar(_selectedImage!);
        if (uploadedUrl != null) {
          avatarUrl = uploadedUrl;
        }
      }

      if (avatarUrl == null) {
        final profile = await supabase
            .from('profiles')
            .select('avatar_url')
            .eq('id', user.id)
            .single()
            .onError(
              (error, stackTrace) => {'error': 'Error at avatar upload'},
            );
        avatarUrl = profile['avatar_url'];
      }

      await supabase.from('profiles').upsert({
        'id': user.id,
        'name': nameCtrl.text.trim(),
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      ref.invalidate(profileProvider);

      if (_selectedImage != null) {
        setState(() => _selectedImage = null);
      }

      _showSnackBar('✅ Profile updated');
      setState(() => _isEditingName = false);
    } catch (e) {
      _showSnackBar('❌ Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Update Profile Picture',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            _ImageOptionTile(
              icon: Icons.camera_alt_rounded,
              title: 'Take Photo',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            _ImageOptionTile(
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImage != null)
              _ImageOptionTile(
                icon: Icons.delete_rounded,
                title: 'Remove Photo',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedImage = null);
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getAvatarUrlWithCacheBuster(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.contains('?')) {
      return '$url&t=${DateTime.now().millisecondsSinceEpoch}';
    }
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final supabase = ref.read(supabaseProvider);
    final user = supabase.auth.currentUser;
    final themeSettings = ref.watch(themeSettingsProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: profileAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Colors.red[400],
              ),
              const SizedBox(height: 20),
              Text(
                'Failed to load profile',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => ref.invalidate(profileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (!mounted) return const SizedBox();

          if (nameCtrl.text.isEmpty) {
            nameCtrl.text =
                profile?['name'] ?? user?.userMetadata?['name'] ?? '';
          }

          final currentAvatarUrl = profile?['avatar_url'];
          final avatarUrlWithCacheBuster = _getAvatarUrlWithCacheBuster(
            currentAvatarUrl,
          );

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                snap: false,
                expandedHeight: 180.0,
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: AnimatedOpacity(
                    opacity: _isEditingName ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: const Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (_isUploading)
                    const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else if (_isEditingName || _selectedImage != null)
                    IconButton(
                      icon: const Icon(Icons.check_rounded),
                      onPressed: _saveProfile,
                      tooltip: 'Save Changes',
                    ),
                ],
              ),

              // Profile Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDarkMode
                              ? [Colors.grey[850]!, Colors.grey[900]!]
                              : [Colors.white, Colors.grey[50]!],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Profile Avatar
                            GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          colorScheme.primary,
                                          colorScheme.primary.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: _selectedImage != null
                                          ? Image.file(
                                              _selectedImage!,
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                            )
                                          : currentAvatarUrl != null &&
                                                currentAvatarUrl.isNotEmpty
                                          ? Image.network(
                                              avatarUrlWithCacheBuster,
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value:
                                                        loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Icon(
                                                      Icons.person_rounded,
                                                      size: 60,
                                                      color: Colors.white
                                                          .withOpacity(0.9),
                                                    );
                                                  },
                                            )
                                          : Icon(
                                              Icons.person_rounded,
                                              size: 60,
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDarkMode
                                              ? Colors.grey[900]!
                                              : Colors.grey[50]!,
                                          width: 3,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Name Field
                            if (_isEditingName)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: nameCtrl,
                                    focusNode: _nameFocusNode,
                                    autofocus: true,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.grey[200]
                                          : Colors.grey[800],
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      hintText: 'Enter your name',
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.check_rounded),
                                        onPressed: _saveProfile,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => setState(() {
                                            _isEditingName = false;
                                            nameCtrl.text =
                                                profile?['name'] ??
                                                user?.userMetadata?['name'] ??
                                                '';
                                          }),
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            else
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nameCtrl.text.isEmpty
                                            ? 'No Name Set'
                                            : nameCtrl.text,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: isDarkMode
                                              ? Colors.grey[200]
                                              : Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user?.email ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_rounded,
                                      color: colorScheme.primary,
                                    ),
                                    onPressed: () {
                                      setState(() => _isEditingName = true);
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            _nameFocusNode.requestFocus();
                                          });
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Theme Settings Section
              // In your SettingsScreen build method, add this section:

              // Theme Settings Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Appearance',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(themeSettingsProvider.notifier)
                                    .resetToDefaults();
                                _showSnackBar('Theme reset to defaults');
                              },
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      ),

                      // Dark/Light Mode Toggle Card
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(
                                        0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.brightness_6_rounded,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Theme Mode',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SegmentedButton<ThemeModeType>(
                                segments: [
                                  ButtonSegment<ThemeModeType>(
                                    value: ThemeModeType.light,
                                    label: const Text('Light'),
                                    icon: const Icon(Icons.light_mode_rounded),
                                  ),
                                  ButtonSegment<ThemeModeType>(
                                    value: ThemeModeType.dark,
                                    label: const Text('Dark'),
                                    icon: const Icon(Icons.dark_mode_rounded),
                                  ),
                                  ButtonSegment<ThemeModeType>(
                                    value: ThemeModeType.system,
                                    label: const Text('Auto'),
                                    icon: const Icon(
                                      Icons.brightness_auto_rounded,
                                    ),
                                  ),
                                ],
                                selected: {themeSettings.themeMode},
                                onSelectionChanged:
                                    (Set<ThemeModeType> newSelection) {
                                      ref
                                          .read(themeSettingsProvider.notifier)
                                          .setThemeMode(newSelection.first);
                                    },
                                style: SegmentedButton.styleFrom(
                                  backgroundColor: isDarkMode
                                      ? Colors.grey[800]
                                      : Colors.grey[100],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Accent Color Selection Card
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(
                                        0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.palette_rounded,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Accent Color',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 50,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: ThemeColor.values.map((color) {
                                    final isSelected =
                                        themeSettings.themeColor == color;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: GestureDetector(
                                        onTap: () {
                                          ref
                                              .read(
                                                themeSettingsProvider.notifier,
                                              )
                                              .setThemeColor(color);
                                        },
                                        child: Container(
                                          width: 50,
                                          decoration: BoxDecoration(
                                            color: color.color,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.transparent,
                                              width: 3,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: color.color.withOpacity(
                                                  0.3,
                                                ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  color: Colors.white,
                                                  size: 24,
                                                )
                                              : null,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Selected: ${themeSettings.themeColor.displayName}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Font Size Adjustment Card
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(
                                        0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.text_fields_rounded,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Font Size',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Slider(
                                value: themeSettings.fontSize.value,
                                min: 14,
                                max: 20,
                                divisions: 3,
                                label: themeSettings.fontSize.displayName,
                                onChanged: (value) {
                                  FontSize newSize;
                                  if (value <= 15)
                                    newSize = FontSize.small;
                                  else if (value <= 17)
                                    newSize = FontSize.medium;
                                  else if (value <= 19)
                                    newSize = FontSize.large;
                                  else
                                    newSize = FontSize.extraLarge;

                                  ref
                                      .read(themeSettingsProvider.notifier)
                                      .setFontSize(newSize);
                                },
                                activeColor: colorScheme.primary,
                                inactiveColor: colorScheme.primary.withOpacity(
                                  0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Small',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Text(
                                    'Large',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Sync Settings with Profile Card
                      Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SwitchListTile(
                          title: const Text(
                            'Sync Settings',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text(
                            'Save appearance settings to your profile',
                          ),
                          value: themeSettings.syncWithProfile,
                          onChanged: (value) {
                            ref
                                .read(themeSettingsProvider.notifier)
                                .setSyncWithProfile(value);

                            if (value) {
                              // If enabling sync, save current settings to profile
                              final syncService = ref.read(
                                profileSyncServiceProvider,
                              );
                              syncService.syncThemeSettingsToProfile();
                              _showSnackBar(
                                'Settings will be synced to your profile',
                              );
                            } else {
                              _showSnackBar(
                                'Settings will be stored locally only',
                              );
                            }
                          },
                          secondary: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              themeSettings.syncWithProfile
                                  ? Icons.cloud_sync_rounded
                                  : Icons.cloud_off_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),

                      // Sync Now Button (only shown when sync is enabled)
                      if (themeSettings.syncWithProfile)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final syncService = ref.read(
                                profileSyncServiceProvider,
                              );
                              syncService.syncThemeSettingsToProfile();
                              _showSnackBar('Settings synced to profile');
                            },
                            icon: const Icon(Icons.sync_rounded),
                            label: const Text('Sync Now'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Account Settings Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 8),
                        child: Text(
                          'Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),

                      // Reset Password Card
                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          onTap: () async {
                            if (user?.email == null) return;

                            await ref
                                .read(authControllerProvider.notifier)
                                .resetPassword(user!.email!);

                            if (!mounted) return;
                            _showSnackBar('Password reset email sent');
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_reset_rounded,
                              color: colorScheme.primary,
                            ),
                          ),
                          title: const Text(
                            'Reset Password',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text(
                            'Receive a password reset link via email',
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey[400],
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),

                      // Logout Card
                      Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        elevation: 0,
                        color: Colors.red.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          onTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Logout'),
                                content: const Text(
                                  'Are you sure you want to logout?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Logout'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .logout();
                            }
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.red,
                            ),
                          ),
                          title: const Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: const Text(
                            'Sign out of your account',
                            style: TextStyle(color: Colors.red),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.red.withOpacity(0.7),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ImageOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback onTap;

  const _ImageOptionTile({
    required this.icon,
    required this.title,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (color ?? Theme.of(context).colorScheme.primary).withOpacity(
            0.1,
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? (isDarkMode ? Colors.grey[200] : Colors.grey[800]),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    );
  }
}

/* 
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../../core/providers/supabase_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final nameCtrl = TextEditingController();
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _isUploading = false;
  bool _isEditingName = false;
  late FocusNode _nameFocusNode;

  @override
  void initState() {
    super.initState();
    _nameFocusNode = FocusNode();
    // Initialize bucket when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureAvatarBucketExists();
    });
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<bool> _ensureAvatarBucketExists() async {
    try {
      final supabase = ref.read(supabaseProvider);

      // Try to list buckets to check if avatars exists
      final buckets = await supabase.storage.listBuckets();
      final avatarBucketExists = buckets.any(
        (bucket) => bucket.id == 'avatars',
      );

      if (!avatarBucketExists) {
        debugPrint('🔄 Creating avatars bucket...');
        try {
          // Create the bucket
          await supabase.storage.createBucket(
            'avatars',
             const BucketOptions(
              public: true,
              fileSizeLimit: '5242880', // 5MB
              allowedMimeTypes: ['image/*'],
            ),
          );
          debugPrint('✅ Created avatars bucket');

          // Try to create RLS policies via SQL
          try {
            await supabase.rpc('create_avatar_policies');
            debugPrint('✅ Created RLS policies');
          } catch (e) {
            debugPrint(
              '⚠️ Could not create policies via RPC, you need to create them manually',
            );
            debugPrint('⚠️ Error: $e');
          }

          return true;
        } catch (createError) {
          debugPrint('⚠️ Error creating bucket: $createError');
          return true;
        }
      }
      debugPrint('✅ Avatars bucket already exists');
      return true;
    } catch (e) {
      debugPrint('❌ Error checking bucket: $e');
      return false;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image: $e');
    }
  }

  Future<String?> _uploadAvatar(File imageFile) async {
    try {
      final supabase = ref.read(supabaseProvider);
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      // Ensure bucket exists before uploading
      final bucketReady = await _ensureAvatarBucketExists();
      if (!bucketReady) {
        _showSnackBar('Failed to prepare storage');
        return null;
      }

      // Create unique filename
      final fileName =
          'avatar_${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Read file as bytes
      final fileBytes = await imageFile.readAsBytes();

      debugPrint('📤 Uploading avatar to bucket: avatars/$fileName');

      try {
        // Upload to Supabase Storage
        await supabase.storage
            .from('avatars')
            .uploadBinary(
              fileName,
              fileBytes,
              fileOptions: const FileOptions(
                upsert: true,
                contentType: 'image/jpeg',
              ),
            );

        // Get public URL
        final publicUrl = supabase.storage
            .from('avatars')
            .getPublicUrl(fileName);

        // Add cache busting parameter
        final urlWithCacheBuster =
            '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

        debugPrint('✅ Avatar uploaded successfully: $urlWithCacheBuster');

        return urlWithCacheBuster;
      } catch (uploadError) {
        debugPrint('❌ Upload error: $uploadError');
        // Try alternative upload method
        try {
          await supabase.storage.from('avatars').upload(fileName, imageFile);

          final publicUrl = supabase.storage
              .from('avatars')
              .getPublicUrl(fileName);

          final urlWithCacheBuster =
              '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
          debugPrint('✅ Avatar uploaded (alternative method): $urlWithCacheBuster');

          return urlWithCacheBuster;
        } catch (altError) {
          debugPrint('❌ Alternative upload also failed: $altError');
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      _showSnackBar('Error uploading image: ${e.toString()}');
      return null;
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isUploading = true);

    try {
      final supabase = ref.read(supabaseProvider);
      final user = supabase.auth.currentUser;
      if (user == null) return;

      String? avatarUrl;

      // Upload new image if selected
      if (_selectedImage != null) {
        final uploadedUrl = await _uploadAvatar(_selectedImage!);
        if (uploadedUrl != null) {
          avatarUrl = uploadedUrl;
        } else {
          // Get current avatar URL from profile if upload failed
          final profile = await supabase
              .from('profiles')
              .select('avatar_url')
              .eq('id', user.id)
              .single()
              .onError((error, stackTrace) => {'error': 'Error'});
          avatarUrl = profile?['avatar_url'];
        }
      } else {
        // Get current avatar URL from profile
        final profile = await supabase
            .from('profiles')
            .select('avatar_url')
            .eq('id', user.id)
            .single()
            .onError((error, stackTrace) => {'e': 'errors'});
        avatarUrl = profile['avatar_url'];
      }

      // Update profile with new data
      await supabase.from('profiles').upsert({
        'id': user.id,
        'name': nameCtrl.text.trim(),
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Force refresh the profile provider immediately
      ref.invalidate(profileProvider);

      // Also refetch to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 500));
      ref.invalidate(profileProvider);

      if (_selectedImage != null) {
        setState(() => _selectedImage = null);
      }

      _showSnackBar('✅ Profile updated successfully');
      setState(() => _isEditingName = false);
    } catch (e) {
      _showSnackBar('❌ Error updating profile: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Update Profile Picture',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            _ImageOptionTile(
              icon: Icons.camera_alt_rounded,
              title: 'Take Photo',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            _ImageOptionTile(
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImage != null)
              _ImageOptionTile(
                icon: Icons.delete_rounded,
                title: 'Remove Photo',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedImage = null);
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getAvatarUrlWithCacheBuster(String? url) {
    if (url == null || url.isEmpty) return '';
    // Check if URL already has query parameters
    if (url.contains('?')) {
      return '$url&t=${DateTime.now().millisecondsSinceEpoch}';
    }
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final supabase = ref.read(supabaseProvider);
    final user = supabase.auth.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: profileAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading profile...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: Colors.red[400],
              ),
              const SizedBox(height: 20),
              Text(
                'Failed to load profile',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => ref.invalidate(profileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (!mounted) return const SizedBox();

          // Initialize controllers only once
          if (nameCtrl.text.isEmpty) {
            nameCtrl.text =
                profile?['name'] ?? user?.userMetadata?['name'] ?? '';
          }

          // Get current avatar URL with cache buster
          final currentAvatarUrl = profile?['avatar_url'];
          final avatarUrlWithCacheBuster = _getAvatarUrlWithCacheBuster(
            currentAvatarUrl,
          );

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                snap: false,
                expandedHeight: 180.0,
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: AnimatedOpacity(
                    opacity: _isEditingName ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: const Text(
                      'Profile Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (_isUploading)
                    const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else if (_isEditingName || _selectedImage != null)
                    IconButton(
                      icon: const Icon(Icons.check_rounded),
                      onPressed: _saveProfile,
                      tooltip: 'Save Changes',
                    ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDarkMode
                              ? [Colors.grey[850]!, Colors.grey[900]!]
                              : [Colors.white, Colors.grey[50]!],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Profile Avatar
                            GestureDetector(
                              onTap: _showImageSourceDialog,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          colorScheme.primary,
                                          colorScheme.primary.withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: _selectedImage != null
                                          ? Image.file(
                                              _selectedImage!,
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                            )
                                          : currentAvatarUrl != null &&
                                                currentAvatarUrl.isNotEmpty
                                          ? Image.network(
                                              avatarUrlWithCacheBuster,
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                              loadingBuilder: (context, child, loadingProgress) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value:
                                                        loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                  .cumulativeBytesLoaded /
                                                              loadingProgress
                                                                  .expectedTotalBytes!
                                                        : null,
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Icon(
                                                      Icons.person_rounded,
                                                      size: 60,
                                                      color: Colors.white
                                                          .withOpacity(0.9),
                                                    );
                                                  },
                                            )
                                          : Icon(
                                              Icons.person_rounded,
                                              size: 60,
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDarkMode
                                              ? Colors.grey[900]!
                                              : Colors.grey[50]!,
                                          width: 3,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Name Field
                            if (_isEditingName)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: nameCtrl,
                                    focusNode: _nameFocusNode,
                                    autofocus: true,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode
                                          ? Colors.grey[200]
                                          : Colors.grey[800],
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: isDarkMode
                                          ? Colors.grey[800]
                                          : Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      hintText: 'Enter your name',
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.check_rounded),
                                        onPressed: _saveProfile,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => setState(() {
                                            _isEditingName = false;
                                            nameCtrl.text =
                                                profile?['name'] ??
                                                user?.userMetadata?['name'] ??
                                                '';
                                          }),
                                          style: OutlinedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            else
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        nameCtrl.text.isEmpty
                                            ? 'No Name Set'
                                            : nameCtrl.text,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: isDarkMode
                                              ? Colors.grey[200]
                                              : Colors.grey[800],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user?.email ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_rounded,
                                      color: colorScheme.primary,
                                    ),
                                    onPressed: () {
                                      setState(() => _isEditingName = true);
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                            _nameFocusNode.requestFocus();
                                          });
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 8),
                        child: Text(
                          'Account Settings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),

                      Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          onTap: () async {
                            if (user?.email == null) return;

                            await ref
                                .read(authControllerProvider.notifier)
                                .resetPassword(user!.email!);

                            if (!mounted) return;
                            _showSnackBar('Password reset email sent');
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_reset_rounded,
                              color: colorScheme.primary,
                            ),
                          ),
                          title: const Text(
                            'Reset Password',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text(
                            'Receive a password reset link via email',
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey[400],
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),

                      Card(
                        margin: const EdgeInsets.only(bottom: 20),
                        elevation: 0,
                        color: Colors.red.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          onTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Logout'),
                                content: const Text(
                                  'Are you sure you want to logout?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Logout'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .logout();
                            }
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.red,
                            ),
                          ),
                          title: const Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: const Text(
                            'Sign out of your account',
                            style: TextStyle(color: Colors.red),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.red.withOpacity(0.7),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ImageOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback onTap;

  const _ImageOptionTile({
    required this.icon,
    required this.title,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (color ?? Theme.of(context).colorScheme.primary).withOpacity(
            0.1,
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? (isDarkMode ? Colors.grey[200] : Colors.grey[800]),
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    );
  }
}
// 

 */

 */
