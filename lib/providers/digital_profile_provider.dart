// lib/providers/digital_profile_provider.dart
import 'package:flutter/material.dart';
import '../models/social_platform.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DigitalProfileData {
  String? username;
  String? displayName;
  String? location;
  String? jobTitle;
  String? companyName;
  String? bio;
  String? profileImageUrl;
  String? companyImageUrl;
  String? bannerImageUrl;
  List<SocialPlatform> socialPlatforms;

  DigitalProfileData({
    this.username,
    this.displayName,
    this.location,
    this.jobTitle,
    this.companyName,
    this.bio,
    this.profileImageUrl,
    this.companyImageUrl,
    this.bannerImageUrl,
    this.socialPlatforms = const [],
  });
}

class DigitalProfileProvider extends ChangeNotifier {
  DigitalProfileData _profileData = DigitalProfileData();
  bool _isDirty = false;

  DigitalProfileData get profileData => _profileData;
  bool get isDirty => _isDirty;

    void updateProfile({
    String? username,
    String? displayName,
    String? location,
    String? jobTitle,
    String? companyName,
    String? bio,
     String? profileImageUrl,
    String? companyImageUrl,
    String? bannerImageUrl,
  }) {
    _profileData = DigitalProfileData(
      username: username ?? _profileData.username,
      displayName: displayName ?? _profileData.displayName,
      location: location ?? _profileData.location,
      jobTitle: jobTitle ?? _profileData.jobTitle,
      companyName: companyName ?? _profileData.companyName,
      bio: bio ?? _profileData.bio,
      profileImageUrl: profileImageUrl ?? _profileData.profileImageUrl,
      companyImageUrl: companyImageUrl ?? _profileData.companyImageUrl,
      bannerImageUrl: bannerImageUrl ?? _profileData.bannerImageUrl,
      socialPlatforms: _profileData.socialPlatforms,
    );
    _isDirty = true;
    notifyListeners();
  }

  Future<String?> checkUsernameAvailability(String username) async {
  if (!RegExp(r'^[a-z0-9]{6,30}$').hasMatch(username)) {
    return 'Username must be 6-30 characters long and contain only lowercase letters and numbers';
  }
  
  final doc = await FirebaseFirestore.instance
      .collection('usernames')
      .doc(username)
      .get();
      
  return doc.exists ? 'Username already taken' : null;
}

Future<bool> reserveUsername(String username) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return false;

  try {
    await FirebaseFirestore.instance
        .collection('usernames')
        .doc(username)
        .set({
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
    return true;
  } catch (e) {
    return false;
  }
}

  void updateSocialPlatforms(List<SocialPlatform> platforms) {
    _profileData.socialPlatforms = platforms;
    _isDirty = true;
    notifyListeners();
  }

  Future<void> saveProfile() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'profileImageUrl': _profileData.profileImageUrl,
         'username': _profileData.username,
        'displayName': _profileData.displayName,
        'location': _profileData.location,
        'jobTitle': _profileData.jobTitle,
        'companyName': _profileData.companyName,
        'bio': _profileData.bio,
        'companyImageUrl': _profileData.companyImageUrl,
        'bannerImageUrl': _profileData.bannerImageUrl,
        
      }, SetOptions(merge: true));

      _isDirty = false;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }
}