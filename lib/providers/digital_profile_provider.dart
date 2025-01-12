// lib/providers/digital_profile_provider.dart
// Central state management for digital profiles, Handles CRUD operations for profiles, Manages profile layouts and social platforms, Implements real-time updates with Firestore
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/social_platform.dart';
import '../models/block.dart'; // Import Block model
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

enum ProfileLayout { classic, portrait, banner }

class SocialPlatformData {
  final String id;
  final String value;
  final int sequence;

  SocialPlatformData({
    required this.id,
    required this.value,
    required this.sequence,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'value': value,
        'sequence': sequence,
  };
}

class DigitalProfileData {
  String id;
  String userId;
  String username;
  String? displayName;
  String? bio;
  String? location;
  String? jobTitle;
  String? companyName;
  String? profileImageUrl;
  String? companyImageUrl;
  String? bannerImageUrl;
  List<SocialPlatform> socialPlatforms;
  DateTime? createdAt;
  DateTime? updatedAt;
  ProfileLayout layout; // Added layout property
  List<Block> blocks; // Added blocks property

  DigitalProfileData({
    required this.id,
    required this.userId,
    required this.username,
    this.displayName,
    this.bio,
    this.location,
    this.jobTitle,
    this.companyName,
    this.profileImageUrl,
    this.companyImageUrl,
    this.bannerImageUrl,
    this.socialPlatforms = const [],
    this.createdAt,
    this.updatedAt,
    this.layout = ProfileLayout.classic, // Default layout value
    this.blocks = const [], // Initialize blocks
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'bio': bio,
      'location': location,
      'jobTitle': jobTitle,
      'companyName': companyName,
      'profileImageUrl': profileImageUrl,
      'companyImageUrl': companyImageUrl,
      'bannerImageUrl': bannerImageUrl,
      'socialPlatforms': socialPlatforms.map((p) => p.toMap()).toList(),
      'createdAt':
          createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'layout': layout.name, // Include layout in toMap
      'blocks': blocks.map((b) => b.toMap()).toList(), // Include blocks in toMap
    };
  }

  factory DigitalProfileData.fromMap(String id, Map<String, dynamic> map) {
    return DigitalProfileData(
      id: id,
      userId: map['userId'],
      username: map['username'],
      displayName: map['displayName'],
      bio: map['bio'],
      location: map['location'],
      jobTitle: map['jobTitle'],
      companyName: map['companyName'],
      profileImageUrl: map['profileImageUrl'],
      companyImageUrl: map['companyImageUrl'],
      bannerImageUrl: map['bannerImageUrl'],
      socialPlatforms: (map['socialPlatforms'] as List?)
              ?.map((p) => SocialPlatform.fromMap(p))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      layout: map['layout'] != null // Add layout to fromMap
          ? ProfileLayout.values.firstWhere(
              (e) => e.name == map['layout'],
              orElse: () => ProfileLayout.banner)
          : ProfileLayout.banner,
          blocks: (map['blocks'] as List?)
          ?.map((b) => Block.fromMap(b))
          .toList() ?? [], // Add blocks to fromMap
    );
  }
}

class DigitalProfileProvider extends ChangeNotifier {
  DigitalProfileData _profileData = DigitalProfileData(
    id: '',
    userId: '',
    username: '',
  );
  bool _isDirty = false;
  ProfileLayout _selectedLayout = ProfileLayout.banner; // Added property
  
  DigitalProfileData get profileData => _profileData;
  bool get isDirty => _isDirty;
  ProfileLayout get selectedLayout => _selectedLayout; // Added getter

  // Added method
  void setLayout(ProfileLayout layout) {
    _selectedLayout = layout;
    _isDirty = true; // Set dirty when layout changes
    notifyListeners();

      // Save layout to Firestore
      FirebaseFirestore.instance
          .collection('digitalProfiles')
          .doc(_profileData.id)
          .update({'layout': layout.name});
  }

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
  }) async {
    _profileData = DigitalProfileData(
      id: _profileData.id,
      userId: _profileData.userId,
      username: username ?? _profileData.username,
      displayName: displayName ?? _profileData.displayName,
      bio: bio ?? _profileData.bio,
      location: location ?? _profileData.location,
      jobTitle: jobTitle ?? _profileData.jobTitle,
      companyName: companyName ?? _profileData.companyName,
      profileImageUrl: profileImageUrl ?? _profileData.profileImageUrl,
      companyImageUrl: companyImageUrl ?? _profileData.companyImageUrl,
      bannerImageUrl: bannerImageUrl ?? _profileData.bannerImageUrl,
      socialPlatforms: _profileData.socialPlatforms,
      createdAt: _profileData.createdAt,
      updatedAt: _profileData.updatedAt,
      layout: _profileData.layout, // Keep existing layout
      blocks: _profileData.blocks, // Keep existing blocks
    );
    _isDirty = true;
    notifyListeners();

    try {
      await saveProfile();
    } catch (e) {
      debugPrint('Auto-save failed: $e');
    }
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

  Future<String?> reserveUsername(String username) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    final batch = FirebaseFirestore.instance.batch();

    final profileRef = FirebaseFirestore.instance.collection('digitalProfiles').doc();

    final profile = DigitalProfileData(
      id: profileRef.id,
      userId: userId,
      username: username,
      displayName: "",
      bio: "",
      location: "",
      jobTitle: "",
      companyName: "",
      profileImageUrl: "",
      companyImageUrl: "",
      bannerImageUrl: "",
      socialPlatforms: [],
      blocks: [], // Initialize blocks
    );

    final usernameRef = FirebaseFirestore.instance.collection('usernames').doc(username);
    batch.set(usernameRef, {
      'userId': userId,
      'profileId': profileRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(profileRef, profile.toMap());

    try {
      await batch.commit();
      return profileRef.id;
    } catch (e) {
      return null;
    }
  }

  void updateSocialPlatforms(List<SocialPlatform> platforms) {
    final platformsWithSequence = platforms.asMap().entries.map((entry) {
      return SocialPlatformData(
        id: entry.value.id,
        value: entry.value.value ?? '',
        sequence: entry.key + 1,
      );
    }).toList();

    _profileData.socialPlatforms = platforms;
    _isDirty = true;

    FirebaseFirestore.instance
        .collection('digitalProfiles')
        .doc(_profileData.id)
        .update({
      'socialPlatforms': platformsWithSequence.map((p) => p.toMap()).toList()
    });

    notifyListeners();
  }

  Future<void> saveProfile() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final profileRef = FirebaseFirestore.instance
          .collection('digitalProfiles')
          .doc(_profileData.id);

      _profileData = _profileData.copyWith(
        updatedAt: DateTime.now(),
      );

      await profileRef.set(_profileData.toMap(), SetOptions(merge: true));

      _isDirty = false;
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  Future<void> loadProfile(String profileId) async {
    try {
      // Clear existing profile data first
      _profileData = DigitalProfileData(
        id: '',
        userId: '',
        username: '',
      );
      notifyListeners();
      
      final doc = await FirebaseFirestore.instance
          .collection('digitalProfiles')
          .doc(profileId)
          .get();

      if (doc.exists) {
        _profileData = DigitalProfileData.fromMap(doc.id, doc.data()!);
        _selectedLayout = _profileData.layout; // Load the layout
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  Future<void> deleteProfile(String profileId) async {
    try {
      final profile = await FirebaseFirestore.instance
          .collection('digitalProfiles')
          .doc(profileId)
          .get();
    
      if (!profile.exists) return;

      final batch = FirebaseFirestore.instance.batch();
    
      // Delete username reservation
      batch.delete(FirebaseFirestore.instance
          .collection('usernames')
          .doc(profile.data()!['username']));
    
      // Delete profile
      batch.delete(FirebaseFirestore.instance
          .collection('digitalProfiles')
          .doc(profileId));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }

  Stream<List<DigitalProfileData>> getProfilesStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('digitalProfiles')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DigitalProfileData.fromMap(doc.id, doc.data()))
            .toList());
  }
    void updateBlocks(List<Block> blocks) {
    _profileData.blocks = blocks;
    _isDirty = true;

    FirebaseFirestore.instance
        .collection('digitalProfiles')
        .doc(_profileData.id)
        .update({
      'blocks': blocks.map((b) => b.toMap()).toList()
    });

    notifyListeners();
  }

  Future<String> uploadBlockImage(Uint8List imageBytes, String blockId) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final ref = FirebaseStorage.instance
        .ref()
        .child('users')
        .child(userId)
        .child('blocks/$blockId/${DateTime.now().millisecondsSinceEpoch}.jpg');

    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'block-id': blockId},
    );

    await ref.putData(imageBytes, metadata);
    return await ref.getDownloadURL();
  }
}

extension DigitalProfileDataExtension on DigitalProfileData {
  DigitalProfileData copyWith({
    String? id,
    String? userId,
    String? username,
    String? displayName,
    String? bio,
    String? location,
    String? jobTitle,
    String? companyName,
    String? profileImageUrl,
    String? companyImageUrl,
    String? bannerImageUrl,
    List<SocialPlatform>? socialPlatforms,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProfileLayout? layout, // Add layout to copyWith
    List<Block>? blocks, // Add blocks to copyWith
  }) {
    return DigitalProfileData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      companyImageUrl: companyImageUrl ?? this.companyImageUrl,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      socialPlatforms: socialPlatforms ?? this.socialPlatforms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layout: layout ?? this.layout, // Include layout in copyWith
      blocks: blocks ?? this.blocks, // Include blocks in copyWith
    );
  }
  
  String getPublicProfileUrl(String username) {
    // Use custom domain when ready, fallback to Firebase hosting
    return 'https://tappglobal-app-profile.web.app/$username';
  }
}