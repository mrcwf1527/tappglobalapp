// lib/providers/digital_profile_provider.dart
import 'package:flutter/material.dart';
import '../models/social_platform.dart';

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

  void updateSocialPlatforms(List<SocialPlatform> platforms) {
    _profileData.socialPlatforms = platforms;
    _isDirty = true;
    notifyListeners();
  }

  Future<void> saveProfile() async {
    // TODO: Implement save to Firebase
    _isDirty = false;
    notifyListeners();
  }
}