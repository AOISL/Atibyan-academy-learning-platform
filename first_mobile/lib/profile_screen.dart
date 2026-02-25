import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:first_mobile/main.dart' show supabase;
import 'login_screen.dart';
import 'help_support_screen.dart'; // ← Remove this line + tile block if not needed

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _isUploading = false;
  String? _avatarUrl;
  String? _fullName;
  String? _email;
  String? _joinDate;
  late final StreamSubscription _authSubscription;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _loadProfile();
      } else {
        if (mounted) {
          setState(() {
            _avatarUrl = null;
            _fullName = null;
            _email = null;
            _joinDate = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final user = supabase.auth.currentUser;
    if (user == null) {
      debugPrint('No user logged in');
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _email = user.email;
    _joinDate = user.createdAt.toString().split(' ').first ?? 'Unknown';

    try {
      debugPrint('Loading profile for user: ${user.id}');
      final response = await supabase
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        debugPrint('No profile found → creating new one');
        await supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': user.userMetadata?['full_name'] as String? ?? 'User',
          'avatar_url': null,
        }, onConflict: 'id');
        debugPrint('Profile created successfully');

        // Reload after creation
        final newResponse = await supabase
            .from('profiles')
            .select('full_name, avatar_url')
            .eq('id', user.id)
            .maybeSingle();

        if (newResponse != null && mounted) {
          setState(() {
            _fullName = newResponse['full_name'] as String? ?? 'User';
            _avatarUrl = newResponse['avatar_url'] as String?;
          });
        }
        return;
      }

      debugPrint('Profile loaded: $response');
      if (mounted) {
        setState(() {
          _fullName = response['full_name'] as String? ?? 'User';
          _avatarUrl = response['avatar_url'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (!mounted) return;

    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose source'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, ImageSource.camera), child: const Text('Camera')),
          TextButton(onPressed: () => Navigator.pop(context, ImageSource.gallery), child: const Text('Gallery')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ],
      ),
    );

    if (source == null || !mounted) return;

    setState(() {
      _isUploading = true;
      _isLoading = true;
    });

    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null || !mounted) {
        setState(() {
          _isUploading = false;
          _isLoading = false;
        });
        return;
      }

      final userId = supabase.auth.currentUser!.id;
      final fileExt = path.extension(pickedFile.path);
      final fileName = '${const Uuid().v4()}$fileExt';
      final filePath = '$userId/$fileName';
      final file = File(pickedFile.path);

      debugPrint('Uploading avatar to: $filePath');

      // Upload to storage
      await supabase.storage.from('avatars').upload(filePath, file);

      // Get public URL
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      debugPrint('Public URL: $publicUrl');

      // UPSERT to profiles (safe for both new & existing rows)
      await supabase.from('profiles').upsert({
        'id': userId,
        'full_name': _fullName ?? 'User',  // Include full_name to avoid NOT NULL violation
        'avatar_url': publicUrl,
      }, onConflict: 'id');

      debugPrint('Avatar URL saved to profile');

      if (mounted) {
        setState(() {
          _avatarUrl = publicUrl;
          _isUploading = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Avatar upload failed: $e');

      if (mounted) {
        setState(() {
          _isUploading = false;
          _isLoading = false;
        });

        String errorMsg = 'Failed to upload image. Please try again.';
        if (e.toString().contains('403') || e.toString().contains('Unauthorized')) {
          errorMsg = 'Permission denied. Please check avatars bucket policies in Supabase.';
        } else if (e.toString().contains('StorageException')) {
          errorMsg = 'Storage error: Try a smaller image or check internet.';
        } else if (e.toString().contains('timeout')) {
          errorMsg = 'Upload timed out. Check your connection and try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await supabase.auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _email == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isLoggedIn = _email != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: isLoggedIn
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Avatar upload
                  GestureDetector(
                    onTap: _isLoading || _isUploading ? null : _pickAndUploadImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                          child: _avatarUrl == null
                              ? Text(
                                  (_fullName?.isNotEmpty == true ? _fullName![0] : _email![0])
                                      .toUpperCase(),
                                  style: const TextStyle(fontSize: 60, color: Colors.white),
                                )
                              : null,
                        ),
                        if (_isUploading)
                          const Positioned.fill(
                            child: Center(child: CircularProgressIndicator(color: Colors.white)),
                          ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    _fullName ?? 'User',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),

                  Text(
                    _email ?? 'No email',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Joined: ${_joinDate ?? 'Unknown'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 48),

                  // Help & Support tile (remove this block if you don't want it)
                  _buildTile(
                    Icons.help_outline,
                    'Help & Support',
                    'FAQs, contact us',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Logout', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _logout,
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  const Text('Not logged in', style: TextStyle(fontSize: 22)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Login'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ).then((_) {
                        if (mounted) _loadProfile();
                      });
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}