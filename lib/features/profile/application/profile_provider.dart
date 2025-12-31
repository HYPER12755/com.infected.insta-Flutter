import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// A model to represent the user's profile data.
class Profile {
  String name;
  String username;
  String bio;
  File? profilePicture;
  DateTime? usernameLastChanged;
  int usernameChangeCount;

  Profile({
    required this.name,
    required this.username,
    this.bio = '',
    this.profilePicture,
    this.usernameLastChanged,
    this.usernameChangeCount = 0,
  });
}

// A provider to manage the state of the user's profile.
class ProfileProvider with ChangeNotifier {
  Profile _profile = Profile(name: 'Your Name', username: 'YourUsername', bio: 'This is your bio!');

  Profile get profile => _profile;

  // Business logic to update the profile.
  Future<bool> updateProfile(String newName, String newUsername, String newBio) async {
    if (newUsername != _profile.username) {
      final now = DateTime.now();
      if (_profile.usernameLastChanged != null &&
          now.difference(_profile.usernameLastChanged!).inDays < 14 &&
          _profile.usernameChangeCount >= 2) {
        // Rule: Cannot change username more than twice in 14 days.
        return false;
      }

      if (_profile.usernameLastChanged == null || now.difference(_profile.usernameLastChanged!).inDays >= 14) {
        // Reset count if 14 days have passed
        _profile.usernameChangeCount = 0;
        _profile.usernameLastChanged = null;
      }

      _profile.usernameChangeCount++;
      if(_profile.usernameLastChanged == null) {
        _profile.usernameLastChanged = now;
      }
    }

    _profile.name = newName;
    _profile.username = newUsername;
    _profile.bio = newBio;

    notifyListeners();
    return true;
  }

  // Logic to update the profile picture.
  Future<void> updateProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _profile.profilePicture = File(pickedFile.path);
      notifyListeners();
    }
  }
}
