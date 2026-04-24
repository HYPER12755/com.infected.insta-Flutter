import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:infected_insta/features/profile/providers/profile_provider.dart';
import 'package:infected_insta/features/create_post/providers/storage_provider.dart';
import 'package:infected_insta/supabase/supabase_client.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _websiteCtrl;
  bool _isSaving = false;
  File? _newAvatar;

  @override
  void initState() {
    super.initState();
    final user = ref.read(profileProvider).user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
    _websiteCtrl = TextEditingController(text: user?.website ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _newAvatar = File(file.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    String? newAvatarUrl;
    if (_newAvatar != null) {
      try {
        final uid = supabase.auth.currentUser?.id ?? '';
        final path = 'avatars/$uid/${const Uuid().v4()}.jpg';
        final storage = SupabaseStorageService(supabase);
        newAvatarUrl = await storage.uploadFile(_newAvatar!.path, path, bucket: 'avatars');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Avatar upload failed: $e')));
        }
        setState(() => _isSaving = false);
        return;
      }
    }

    final ok = await ref.read(profileProvider.notifier).updateProfile(
      fullName: _nameCtrl.text.trim(),
      username: _usernameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      website: _websiteCtrl.text.trim(),
      avatarUrl: newAvatarUrl,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (ok) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update profile. Please try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final user = ref.watch(profileProvider).user;
    final currentAvatar = user?.avatarUrl ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('Edit Profile'),
        actions: [
          _isSaving
              ? const Padding(padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : TextButton(
                  onPressed: _save,
                  child: Text('Done', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(children: [
            // Avatar
            GestureDetector(
              onTap: _pickAvatar,
              child: Stack(alignment: Alignment.bottomRight, children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: const Color(0xFF2A2A3E),
                  backgroundImage: _newAvatar != null
                      ? FileImage(_newAvatar!) as ImageProvider
                      : (currentAvatar.isNotEmpty
                          ? CachedNetworkImageProvider(currentAvatar)
                          : null),
                  child: (_newAvatar == null && currentAvatar.isEmpty)
                      ? const FaIcon(FontAwesomeIcons.user, size: 42, color: Colors.white54)
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primary, shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0D0D1A), width: 2),
                  ),
                  child: const FaIcon(FontAwesomeIcons.pen, size: 12, color: Colors.white),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Text('Change profile photo',
                style: TextStyle(color: primary, fontWeight: FontWeight.w500)),
            const SizedBox(height: 28),

            _field(_nameCtrl, 'Display Name', validator: (v) =>
                (v == null || v.isEmpty) ? 'Name is required' : null),
            const SizedBox(height: 16),
            _field(_usernameCtrl, 'Username',
              prefix: const Text('@', style: TextStyle(color: Colors.white54)),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Username is required';
                if (v.length < 3) return 'At least 3 characters';
                if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(v)) {
                  return 'Only letters, numbers, . and _';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _field(_bioCtrl, 'Bio', maxLines: 4, maxLength: 150),
            const SizedBox(height: 12),
            _field(_websiteCtrl, 'Website', hint: 'https://yoursite.com'),
            const SizedBox(height: 32),

            SizedBox(width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {int maxLines = 1, int? maxLength, Widget? prefix, String? Function(String?)? validator, String? hint}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      maxLength: maxLength,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        prefix: prefix,
        filled: true,
        fillColor: const Color(0xFF1E1E2E),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Theme.of(context).primaryColor)),
      ),
    );
  }
}
